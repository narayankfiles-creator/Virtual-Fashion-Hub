# -*- coding: utf-8 -*-
from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import base64
import io
import uuid
import time
import requests
import json
import os
from PIL import Image
import uvicorn
import asyncio

app = FastAPI(title="Virtual Try-On API", version="1.0.0")

# Updated CORS - Allow all origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Function to get ngrok public URL dynamically
def get_ngrok_url():
    try:
        response = requests.get("http://127.0.0.1:4040/api/tunnels", timeout=5)
        response.raise_for_status()
        tunnels = response.json().get("tunnels", [])
        for tunnel in tunnels:
            if tunnel.get("proto") == "https":
                return tunnel.get("public_url")
    except Exception as e:
        print(f"Error fetching ngrok URL: {e}")
    return None

# Fetch ngrok URL at startup
NGROK_URL = get_ngrok_url()
if NGROK_URL:
    print(f"Using Ngrok public URL: {NGROK_URL}")
else:
    print("Ngrok URL not found. Please start ngrok.")

COMFYUI_URL = "http://127.0.0.1:8188"
CLIENT_ID = str(uuid.uuid4())

WORKFLOW_API_PATH = os.path.join(os.path.dirname(__file__), 'sm4ll_workflow_api.json')

try:
    with open(WORKFLOW_API_PATH, 'r') as f:
        WORKFLOW_TEMPLATE = json.load(f)
    print("✅ Workflow template loaded successfully")
except FileNotFoundError:
    print("ERROR: sm4ll_workflow_api.json not found! Please export your workflow as API format.")
    WORKFLOW_TEMPLATE = None

def upload_image_to_comfyui(image_bytes, filename):
    try:
        files = {
            'image': (filename, io.BytesIO(image_bytes), 'image/jpeg')
        }
        data = {
            'type': 'input',
            'overwrite': 'true'  # forces ComfyUI to use new image
        }
        response = requests.post(f"{COMFYUI_URL}/upload/image", files=files, data=data)
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Uploaded to ComfyUI: {result}")
            return result['name']
        else:
            raise Exception(f"Upload failed: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"❌ Upload error: {e}")
        raise e

async def call_comfyui_sm4ll_wrapper(person_image_bytes, garment_image_bytes, model_choice):
    if WORKFLOW_TEMPLATE is None:
        raise Exception("Workflow template not loaded. Please export your workflow as API format.")

    workflow = json.loads(json.dumps(WORKFLOW_TEMPLATE))
    job_id = str(uuid.uuid4())
    print(f"🔄 Processing job: {job_id}")

    person_filename = "000.png"
    garment_filename = "00_upper.jpg"

    print("📤 Uploading person image to ComfyUI...")
    actual_person_name = upload_image_to_comfyui(person_image_bytes, person_filename)
    print("📤 Uploading garment image to ComfyUI...")
    actual_garment_name = upload_image_to_comfyui(garment_image_bytes, garment_filename)

    workflow["21"]["inputs"]["image"] = actual_person_name
    workflow["22"]["inputs"]["image"] = actual_garment_name
    workflow["20"]["inputs"]["model_choice"] = model_choice

    print(f"🧑 Updated person image node 21: {actual_person_name}")
    print(f"👕 Updated garment image node 22: {actual_garment_name}")
    print(f"⚙️ Updated model choice: {model_choice}")

    prompt_data = {"prompt": workflow, "client_id": CLIENT_ID}
    response = requests.post(f"{COMFYUI_URL}/prompt", json=prompt_data, timeout=30)

    if response.status_code != 200:
        raise Exception(f"ComfyUI request failed: {response.status_code} - {response.text}")

    prompt_id = response.json()["prompt_id"]
    print(f"📝 ComfyUI prompt queued: {prompt_id}")

    max_wait = 300
    wait_time = 0
    while wait_time < max_wait:
        try:
            history_response = requests.get(f"{COMFYUI_URL}/history/{prompt_id}")
            if history_response.status_code == 200:
                history = history_response.json()
                if prompt_id in history:
                    print("✅ ComfyUI processing completed!")
                    outputs = history[prompt_id]["outputs"]
                    for node_output in outputs.values():
                        if "images" in node_output:
                            for img_info in node_output["images"]:
                                print(f"🖼️ Found output image: {img_info['filename']}")
                                img_url = f"{COMFYUI_URL}/view"
                                params = {
                                    "filename": img_info["filename"],
                                    "subfolder": img_info["subfolder"],
                                    "type": img_info["type"]
                                }
                                img_resp = requests.get(img_url, params=params)
                                if img_resp.status_code == 200:
                                    image_b64 = base64.b64encode(img_resp.content).decode("utf-8")
                                    return image_b64
                    break
        except Exception as e:
            print(f"⚠️ Polling error: {e}")

        await asyncio.sleep(2)
        wait_time += 2

    raise Exception("ComfyUI processing timeout")

@app.get("/")
async def root():
    return {"message": "Virtual Try-On API is running!", "status": "healthy", "ngrok_url": NGROK_URL}

# NEW: Endpoint to get current ngrok URL
@app.get("/api/ngrok-url")
async def get_current_ngrok_url():
    current_url = get_ngrok_url()
    return {"ngrok_url": current_url, "detected_at_startup": NGROK_URL}

@app.post("/api/virtual-tryon")
async def virtual_tryon(
    person_image: UploadFile = File(...),
    garment_image: UploadFile = File(...),
    model_choice: str = Form(...)
):
    valid_choices = ["top garment", "full-body", "eyewear", "footwear"]
    if model_choice not in valid_choices:
        raise HTTPException(status_code=400, detail=f"Invalid model_choice. Must be one of: {valid_choices}")

    try:
        person_bytes = await person_image.read()
        garment_bytes = await garment_image.read()

        print(f"📤 Received images from Flutter: {person_image.filename}, {garment_image.filename}")
        print(f"🎯 Model choice received: {model_choice}")

        try:
            Image.open(io.BytesIO(person_bytes))
            Image.open(io.BytesIO(garment_bytes))
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Invalid image: {e}")

        job_id = str(uuid.uuid4())
        start_time = time.time()

        result_image_b64 = await call_comfyui_sm4ll_wrapper(person_bytes, garment_bytes, model_choice)

        processing_time = time.time() - start_time

        return JSONResponse(content={
            "success": True,
            "job_id": job_id,
            "result_image": result_image_b64,
            "processing_time": round(processing_time, 2),
            "model_choice": model_choice,
            "message": "Virtual try-on completed successfully"
        })
    except Exception as e:
        print(f"❌ Processing error: {e}")
        raise HTTPException(status_code=500, detail=f"Processing failed: {str(e)}")

@app.get("/api/model-choices")
async def get_model_choices():
    return {
        "choices": [
            {"value": "top garment", "label": "Top Garment", "description": "Shirts, Blouses"},
            {"value": "full-body", "label": "Full Body", "description": "Dresses, Complete Outfits"},
            {"value": "eyewear", "label": "Eyewear", "description": "Glasses, Sunglasses"},
            {"value": "footwear", "label": "Footwear", "description": "Shoes, Boots"}
        ]
    }

@app.get("/api/comfyui-status")
async def check_comfyui_status():
    try:
        response = requests.get(f"{COMFYUI_URL}/system_stats", timeout=5)
        return {"comfyui_status": "online", "details": response.json()}
    except:
        return {"comfyui_status": "offline", "details": "ComfyUI not accessible"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)

# -*- coding: utf-8 -*-
import os
from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import base64
import io
import uuid
import time
import requests
import json
from PIL import Image
import uvicorn
import asyncio

app = FastAPI(title="Virtual Try-On API", version="1.0.0")

# 🔒 SECURE: Environment-based configuration
COMFYUI_URL = os.getenv("COMFYUI_URL", "http://localhost:8188")
NGROK_TUNNEL_URL = os.getenv("NGROK_TUNNEL_URL", "http://localhost:4040")
CLIENT_ID = str(uuid.uuid4())

# 🔒 SECURE: Restrictive CORS configuration
ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "http://localhost:3000,http://localhost:8080").split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,  # Only allow specified origins
    allow_credentials=True,
    allow_methods=["GET", "POST"],  # Only necessary methods
    allow_headers=["*"],
)

# 🔒 SECURE: Optional ngrok URL fetching (disabled by default)
def get_ngrok_url():
    """Fetch ngrok URL only if explicitly enabled"""
    if os.getenv("ENABLE_NGROK_DISCOVERY", "false").lower() == "true":
        try:
            response = requests.get(f"{NGROK_TUNNEL_URL}/api/tunnels", timeout=5)
            response.raise_for_status()
            tunnels = response.json().get("tunnels", [])
            for tunnel in tunnels:
                if tunnel.get("proto") == "https":
                    return tunnel.get("public_url")
        except Exception as e:
            print(f"Error fetching ngrok URL: {e}")
    return None

# Initialize ngrok URL only if enabled
NGROK_URL = get_ngrok_url()
if NGROK_URL:
    print(f"Using Ngrok public URL: {NGROK_URL}")
else:
    print("Ngrok discovery disabled or not found.")

# 🔒 SECURE: Configurable workflow path
WORKFLOW_API_PATH = os.getenv("WORKFLOW_PATH", 
    os.path.join(os.path.dirname(__file__), 'sm4ll_workflow_api.json'))

# Load workflow template securely
try:
    with open(WORKFLOW_API_PATH, 'r') as f:
        WORKFLOW_TEMPLATE = json.load(f)
    print("✅ Workflow template loaded successfully")
except FileNotFoundError:
    print(f"ERROR: {WORKFLOW_API_PATH} not found! Please export your workflow as API format.")
    WORKFLOW_TEMPLATE = None

def upload_image_to_comfyui(image_bytes, filename):
    """Upload image to ComfyUI with error handling"""
    try:
        files = {
            'image': (filename, io.BytesIO(image_bytes), 'image/jpeg')
        }
        data = {
            'type': 'input',
            'overwrite': 'true'
        }
        response = requests.post(f"{COMFYUI_URL}/upload/image", files=files, data=data, timeout=30)
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
    """Process images through ComfyUI workflow"""
    if WORKFLOW_TEMPLATE is None:
        raise Exception("Workflow template not loaded. Please export your workflow as API format.")

    workflow = json.loads(json.dumps(WORKFLOW_TEMPLATE))
    job_id = str(uuid.uuid4())
    print(f"🔄 Processing job: {job_id}")

    # Use secure filenames
    person_filename = f"person_{job_id}.png"
    garment_filename = f"garment_{job_id}.jpg"

    print("📤 Uploading person image to ComfyUI...")
    actual_person_name = upload_image_to_comfyui(person_image_bytes, person_filename)
    print("📤 Uploading garment image to ComfyUI...")
    actual_garment_name = upload_image_to_comfyui(garment_image_bytes, garment_filename)

    # Update workflow with uploaded images
    workflow["21"]["inputs"]["image"] = actual_person_name
    workflow["22"]["inputs"]["image"] = actual_garment_name
    workflow["20"]["inputs"]["model_choice"] = model_choice

    print(f"🧑 Updated person image node 21: {actual_person_name}")
    print(f"👕 Updated garment image node 22: {actual_garment_name}")
    print(f"⚙️ Updated model choice: {model_choice}")

    # Submit workflow to ComfyUI
    prompt_data = {"prompt": workflow, "client_id": CLIENT_ID}
    response = requests.post(f"{COMFYUI_URL}/prompt", json=prompt_data, timeout=30)

    if response.status_code != 200:
        raise Exception(f"ComfyUI request failed: {response.status_code} - {response.text}")

    prompt_id = response.json()["prompt_id"]
    print(f"📝 ComfyUI prompt queued: {prompt_id}")

    # Poll for completion
    max_wait = int(os.getenv("MAX_PROCESSING_TIME", "300"))  # Configurable timeout
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
                                img_resp = requests.get(img_url, params=params, timeout=30)
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
    return {
        "message": "Virtual Try-On API is running!", 
        "status": "healthy",
        "version": "1.0.0"
    }

# 🔒 SECURE: Only expose ngrok URL if explicitly enabled
@app.get("/api/status")
async def get_api_status():
    """Get API status without exposing sensitive information"""
    return {
        "status": "running",
        "comfyui_connected": await check_comfyui_connection(),
        "workflow_loaded": WORKFLOW_TEMPLATE is not None
    }

@app.post("/api/virtual-tryon")
async def virtual_tryon(
    person_image: UploadFile = File(...),
    garment_image: UploadFile = File(...),
    model_choice: str = Form(...)
):
    """Main virtual try-on endpoint"""
    valid_choices = ["top garment", "full-body", "eyewear", "footwear"]
    if model_choice not in valid_choices:
        raise HTTPException(status_code=400, detail=f"Invalid model_choice. Must be one of: {valid_choices}")

    # Validate file types
    if not person_image.content_type.startswith('image/'):
        raise HTTPException(status_code=400, detail="Person image must be an image file")
    if not garment_image.content_type.startswith('image/'):
        raise HTTPException(status_code=400, detail="Garment image must be an image file")

    try:
        person_bytes = await person_image.read()
        garment_bytes = await garment_image.read()

        # Validate image size (prevent DoS)
        max_size = int(os.getenv("MAX_IMAGE_SIZE", "10485760"))  # 10MB default
        if len(person_bytes) > max_size or len(garment_bytes) > max_size:
            raise HTTPException(status_code=400, detail="Image size too large")

        print(f"📤 Processing images: {person_image.filename}, {garment_image.filename}")
        print(f"🎯 Model choice: {model_choice}")

        # Validate images
        try:
            Image.open(io.BytesIO(person_bytes))
            Image.open(io.BytesIO(garment_bytes))
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Invalid image format: {e}")

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
        raise HTTPException(status_code=500, detail="Processing failed")

@app.get("/api/model-choices")
async def get_model_choices():
    """Get available model choices"""
    return {
        "choices": [
            {"value": "top garment", "label": "Top Garment", "description": "Shirts, Blouses"},
            {"value": "full-body", "label": "Full Body", "description": "Dresses, Complete Outfits"},
            {"value": "eyewear", "label": "Eyewear", "description": "Glasses, Sunglasses"},
            {"value": "footwear", "label": "Footwear", "description": "Shoes, Boots"}
        ]
    }

async def check_comfyui_connection():
    """Check if ComfyUI is accessible"""
    try:
        response = requests.get(f"{COMFYUI_URL}/system_stats", timeout=5)
        return response.status_code == 200
    except:
        return False

@app.get("/api/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "comfyui_status": "online" if await check_comfyui_connection() else "offline"
    }

if __name__ == "__main__":
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=False)

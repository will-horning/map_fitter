import json, requests
from leaflet_image_overlay import app
from flask import render_template



@app.route('/', methods=['GET'])
def index():
    return render_template('index.html')


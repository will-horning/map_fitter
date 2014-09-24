from flask import Flask
from flask.ext.cake import Cake

app = Flask(__name__)
app.config['DEBUG'] = True
cake = Cake(app)

import map_fitter.views

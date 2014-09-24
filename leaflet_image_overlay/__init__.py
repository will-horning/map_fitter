from flask import Flask
from flask.ext.cake import Cake

app = Flask(__name__)
app.config['DEBUG'] = True
# cake = Cake(app)
# mongo_url = os.environ.get('MONGOHQ_URL')
# if mongo_url:
#     mongo_conn = pymongo.Connection(mongo_url)
#     mongo = mongo_conn.dcmap
# else:
#     mongo_conn = pymongo.Connection('localhost', 27017)
#     mongo = mongo_conn['dcmap']

# mongo_conn = pymongo.Connection(mongo_url)
# mongo = mongo_conn.dcmap

import leaflet_image_overlay.views

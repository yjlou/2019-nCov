wget 'https://services5.arcgis.com/dlrDjz89gx9qyfev/arcgis/rest/services/Corona_Exposure_View/FeatureServer/0/query?f=json&where=1%3D1&returnGeometry=true&spatialRel=esriSpatialRelIntersects&outFields=*&maxRecordCountFactor=4&outSR=4326&resultOffset=0&resultRecordCount=8000&cacheHint=true' >input.json
nodejs converter.js -i input.json -o output.json

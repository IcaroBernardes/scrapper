# 0. Setup inicial ##########
## Carrega as bibliotecas
import requests
import base64
import json

# 1. Quebra de captcha ##########
## Define função para ler a imagem e enviar para o API
def solve(f):
	with open(f, "rb") as image_file:
		encoded_string = base64.b64encode(image_file.read()).decode('ascii')
		url = 'https://api.apitruecaptcha.org/one/gettext'

		data = { 
			'userid':'usuarioteste@servico.com', 
			'apikey':'minhachavedeapi',  
			'data':encoded_string
		}
		response = requests.post(url = url, json = data)
		data = response.json()
		return data

## Aplica a função ao captcha
text = solve("imagem/captcha.png")

## Converte a json
json_object = json.dumps(text)

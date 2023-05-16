# 0. Setup inicial ##########
## Carrega as bibliotecas
import tabula
import os
import glob

# 1. Extração ##########
## Define os paths
path = "ibama/" ### Path com os pdfs
path2 = "resultados/content_pdf/ibama_csv/" ### Path de output

## Mapeia os arquivos na pasta ibama com padrão .pdf
## depois gera um nome que é igual porém com padrão .csv
## Por fim, salva no diretorio ibama_csv/
for filepath in glob.glob(path+'*.pdf'):
    name=os.path.basename(filepath)
    tabula.convert_into(input_path=filepath, 
                        output_path=path2+name+".csv",
                        pages="all")

# Demonstrativo de webscrap e extração de pdfs

## Webscrap por requisição
Se fundamenta em simular requisições (GET e POST) realizadas pela página durante o processo de envio de entradas e carregamento de resultados.

🎯 Exemplo: extrair as faixas de renda familiar (por pessoa e família) nos municípios do Acre contidos nessa [página](https://cecad.cidadania.gov.br/tab_cad.php)

![](thumbs/thumb_request.png)

📃 [Código](https://github.com/IcaroBernardes/scrapper/blob/master/scripts/webscrap_request.R)

🗂 [Resultado](https://github.com/IcaroBernardes/scrapper/blob/master/resultados/content_request.xlsx)

## Webscrap por URL
Usado em casos em que a página permite o envio de entradas e carregamento de resultados através da URL. Usualmente têm requisições por trás (GET e POST).

## Webscrap por headless browser
Usada em casos em que não está claro como ocorre o envio de entradas e carregamento de resultados de uma página. Isto é, requisições (GET e POST) ou envio por url não são possíveis.

🎯 Exemplo: extrair os períodos de redução de pressão da água em bairros da capital de SP nessa [página](https://reducaopressao.sabesp.com.br)

![](thumbs/thumb_headless_browser.png)

📃 [Código](https://github.com/IcaroBernardes/scrapper/blob/master/scripts/webscrap_headless_browser.R)

🗂 [Resultado](https://github.com/IcaroBernardes/scrapper/blob/master/resultados/content_headless_browser.xlsx)

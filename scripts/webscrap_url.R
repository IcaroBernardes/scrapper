# 0. Setup inicial ###########
## Carrega bibliotecas
library(dplyr)
library(glue)
library(httr)
library(lubridate)
library(readxl)
library(rvest)
library(stringr)
library(xlsx)
library(xml2)

## Carrega as chaves a serem buscadas
chaves <- c("políticas públicas", "FGV")

## Carrega o histórico de links
links <- readxl::read_xlsx("resultados/content_url.xlsx")

# 1. Scrap dos links ###########
## Extrai a lista de links obtidos na busca pelas chaves
for (i in seq_along(chaves)) {
  
  ## Define os parâmetros de busca
  q = chaves[i]
  periodo = "todos"
  site = "todos"
  
  ## Faz o 1o pedido para obter o total de resultados
  url = glue::glue("https://search.folha.uol.com.br/search?q={q}&periodo={periodo}&site={site}")
  url = URLencode(url)
  response = httr::GET(url)
  content = httr::content(response)
  nodes = rvest::html_elements(content, ".col.col--1-1.col--md-1-2.col--lg-1-2.c-search__result")
  total_results = rvest::html_text(nodes) |> 
    stringr::str_extract("[:digit:]+") |> 
    as.numeric()
  
  ## Calcula o total de páginas e põe um limite de 5 páginas por chave
  link_per_page = 25
  total_pages = (total_results %/% link_per_page) + 1*(total_results %% link_per_page > 0)
  if (total_pages > 5) total_pages <- 5
  
  ## Lista urls dos artigos já obtidos para uma chave
  priori = links |>
    dplyr::filter(chave == q) |>
    dplyr::pull(url_news)
  
  ## Busca através das páginas até chegar ao fim ou atingir um link já obtido
  keepgoing = TRUE
  page = 0
  while (keepgoing) {
    
    ### Define a página
    page = page + 1
    
    ### Indica progresso
    print(glue::glue('Buscando por "{q}" | Página {page} de {total_pages}...'))
    
    ### Define a url
    offset = 1+25*(page-1)
    url = glue::glue("https://search.folha.uol.com.br/search?q={q}&periodo={periodo}&site={site}&sr={offset}")
    
    ### Põe a url no encode típico da web
    url = URLencode(url)
    
    ### Efetua a request e extrai seu conteúdo HTML
    response = httr::GET(url)
    content = httr::content(response)
    
    ### Extrai os nós que contém info dos artigos
    nodes = rvest::html_elements(content, "#view-view")
    
    ### Extrai link e título dos artigos
    data = nodes |> 
      purrr::map_dfr(function(x) {
        
        link = x |> 
          rvest::html_element("div.c-headline__content a") |> 
          xml2::xml_attr("href")
        
        titulo = x |> 
          rvest::html_element("h2.c-headline__title") |> 
          rvest::html_text2()
        
        dplyr::tibble(
          chave = q,
          url_news = link,
          titulo = titulo,
          scrap = lubridate::force_tz(Sys.time(), "Brazil/East")
        )
        
      })
    
    ### Elimina artigos já obtidos (compara urls)
    if (nrow(data) == 0) {
      keepgoing = FALSE
    } else {
      data = data |> 
        dplyr::filter(!(url_news %in% priori)) |>
        dplyr::distinct(url_news, .keep_all = TRUE)
    }
    
    ### Confirma se há algo novo ainda a adicionar
    if (nrow(data) == 0) {
      keepgoing = FALSE
    } else {
      links = dplyr::bind_rows(links, data)
    }
    
    ### Confirma se já foi atingida a página final
    if (page == total_pages) {
      keepgoing = FALSE
    }
    
  }
  
}

## Elimina páginas não-padrão
links <- links |> 
  dplyr::filter(stringr::str_detect(url_news, "www1.folha.uol.com.br|top-of-mind.folha.uol.com.br"))

## Salva os resultados obtidos
links <- as.data.frame(links)
xlsx::write.xlsx(links, "resultados/content_url.xlsx", row.names = FALSE)

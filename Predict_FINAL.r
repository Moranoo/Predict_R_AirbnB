# Charger les librairies nécessaires
library(tidyverse)
library(randomForest)
library(shiny)

# Charger les données 
data <- read.csv("./listings.csv")

# Préparation des données
# Extraction et nettoyage de la colonne 'price'
data$price <- as.numeric(gsub("[$,]", "", data$price))
data <- data %>% drop_na(price)

# Transformation logarithmique pour réduire les valeurs extrêmes
data$log_price <- log(data$price)

# Calcul du prix moyen par quartier
neighbourhood_means <- data %>%
    group_by(neighbourhood_cleansed) %>%
    summarise(mean_price = mean(price, na.rm = TRUE))

# Ajout du prix moyen de chaque quartier et classification en catégories
data <- data %>%
    left_join(neighbourhood_means, by = "neighbourhood_cleansed")
data$price_category <- cut(data$mean_price, 
                           breaks = quantile(data$mean_price, probs = c(0, 0.33, 0.66, 1)), 
                           labels = c("non_populaire", "proche_populaire", "populaire"), 
                           include.lowest = TRUE)

# Sélection des variables pour l'entraînement
train_data <- data %>% select(accommodates, bathrooms, bedrooms, price_category, log_price)
train_data$price_category <- as.factor(train_data$price_category)

# Entraîner les modèles sur log(price) en incluant la variable `price_category`
linear_model <- lm(log_price ~ accommodates + bathrooms + bedrooms + price_category, data = train_data)
rf_model <- randomForest(log_price ~ accommodates + bathrooms + bedrooms + price_category, data = train_data, ntree = 100)

# Calcul du MSE et RMSE pour les deux modèles sur le jeu d'entraînement
predicted_price_lm <- exp(predict(linear_model, newdata = train_data))
predicted_price_rf <- exp(predict(rf_model, newdata = train_data))
actual_price <- exp(train_data$log_price)

mse_lm <- mean((actual_price - predicted_price_lm)^2)
mse_rf <- mean((actual_price - predicted_price_rf)^2)
rmse_lm <- sqrt(mse_lm)
rmse_rf <- sqrt(mse_rf)

# Interface utilisateur Shiny
ui <- fluidPage(
    titlePanel("Prédiction du Prix en fonction des caractéristiques"),
    sidebarLayout(
        sidebarPanel(
            numericInput("accommodates", "Accommodates", value = 1, min = 1, max = 10),
            numericInput("bathrooms", "Bathrooms", value = 1, min = 1, max = 5),
            numericInput("bedrooms", "Bedrooms", value = 1, min = 1, max = 5),
            selectInput("price_category", "Catégorie de Prix du Quartier", 
                        choices = c("Non Populaire" = "non_populaire", 
                                    "Proche Populaire" = "proche_populaire", 
                                    "Populaire" = "populaire"), 
                        selected = "proche_populaire"),
            actionButton("predict", "Prédire le prix")
        ),
        mainPanel(
            tabsetPanel(
                tabPanel("Prédictions",
                    h4("Détails de la Prédiction"),
                    textOutput("predicted_price_lm"),
                    textOutput("predicted_price_rf")
                ),
                tabPanel("Évaluation du Modèle",
                    h4("Résumé du Modèle Linéaire"),
                    verbatimTextOutput("summary_lm"),
                    h4("Importance des Variables (Random Forest)"),
                    verbatimTextOutput("importance_rf"),
                    h4("Métriques d'Évaluation"),
                    textOutput("mse_rmse_lm"),
                    textOutput("mse_rmse_rf")
                ),
                tabPanel("Graphiques",
                    h4("Graphique de Régression (log_price vs accommodates)"),
                    plotOutput("regression_plot"),
                    h4("Diagramme en Moustache du Prix par Catégorie de Quartier"),
                    plotOutput("boxplot_price_category")
                )
            )
        )
    )
)

# Serveur Shiny
server <- function(input, output) {
    observeEvent(input$predict, {
        # Créer un dataframe pour les nouvelles données en fonction des entrées de l'utilisateur
        new_data <- data.frame(
            accommodates = input$accommodates,
            bathrooms = input$bathrooms,
            bedrooms = input$bedrooms,
            price_category = factor(input$price_category, levels = c("non_populaire", "proche_populaire", "populaire"))
        )
        
        # Prédictions des prix (en logarithme)
        predicted_price_lm_log <- predict(linear_model, newdata = new_data)
        predicted_price_rf_log <- predict(rf_model, newdata = new_data)
        
        # Reconversion en prix réel en appliquant l'exponentielle
        frais_menage <- 20
        taxes <- 13
        predicted_price_lm <- exp(predicted_price_lm_log)
        predicted_price_rf <- exp(predicted_price_rf_log)
        total_lm <- predicted_price_lm + frais_menage + taxes
        total_rf <- predicted_price_rf + frais_menage + taxes
        
        # Affichage des résultats
        output$predicted_price_lm <- renderText({
            paste("Régression Linéaire - Prix prédit :", round(predicted_price_lm, 2), "€ | Frais de ménage :", frais_menage, "€ | Taxes :", taxes, "€ | Total :", round(total_lm, 2), "€")
        })
        
        output$predicted_price_rf <- renderText({
            paste("Random Forest - Prix prédit :", round(predicted_price_rf, 2), "€ | Frais de ménage :", frais_menage, "€ | Taxes :", taxes, "€ | Total :", round(total_rf, 2), "€")
        })
    })
    
    # Affichage des résumés et des métriques d'évaluation
    output$summary_lm <- renderPrint({
        summary(linear_model)
    })
    
    output$importance_rf <- renderPrint({
        importance(rf_model)
    })
    
    output$mse_rmse_lm <- renderText({
        paste("Régression Linéaire - MSE :", round(mse_lm, 2), "| RMSE :", round(rmse_lm, 2))
    })
    
    output$mse_rmse_rf <- renderText({
        paste("Random Forest - MSE :", round(mse_rf, 2), "| RMSE :", round(rmse_rf, 2))
    })
    
    # Graphique de régression
    output$regression_plot <- renderPlot({
        ggplot(train_data, aes(x = accommodates, y = log_price)) +
            geom_point(alpha = 0.5) +
            geom_smooth(method = "lm", color = "blue") +
            labs(x = "Accommodates", y = "Log Price", title = "Relation entre Accommodates et Log Price")
    })
    
    # Diagramme en moustache (Boxplot)
    output$boxplot_price_category <- renderPlot({
        ggplot(train_data, aes(x = price_category, y = price)) +
            geom_boxplot() +
            labs(x = "Catégorie de Quartier", y = "Prix", title = "Distribution des Prix par Catégorie de Quartier")
    })
}

# Lancer l'application Shiny
shinyApp(ui = ui, server = server)

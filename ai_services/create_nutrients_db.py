import json
import requests
import os
import time

# Food-101 categories
food101_categories = [
    "apple_pie", "baby_back_ribs", "baklava", "beef_carpaccio", "beef_tartare", 
    "beet_salad", "beignets", "bibimbap", "bread_pudding", "breakfast_burrito", 
    "bruschetta", "caesar_salad", "cannoli", "caprese_salad", "carrot_cake", 
    "ceviche", "cheesecake", "cheese_plate", "chicken_curry", "chicken_quesadilla", 
    "chicken_wings", "chocolate_cake", "chocolate_mousse", "churros", "clam_chowder", 
    "club_sandwich", "crab_cakes", "creme_brulee", "croque_madame", "cup_cakes", 
    "deviled_eggs", "donuts", "dumplings", "edamame", "eggs_benedict", 
    "escargots", "falafel", "filet_mignon", "fish_and_chips", "foie_gras", 
    "french_fries", "french_onion_soup", "french_toast", "fried_calamari", "fried_rice", 
    "frozen_yogurt", "garlic_bread", "gnocchi", "greek_salad", "grilled_cheese_sandwich", 
    "grilled_salmon", "guacamole", "gyoza", "hamburger", "hot_and_sour_soup", 
    "hot_dog", "huevos_rancheros", "hummus", "ice_cream", "lasagna", 
    "lobster_bisque", "lobster_roll_sandwich", "macaroni_and_cheese", "macarons", "miso_soup", 
    "mussels", "nachos", "omelette", "onion_rings", "oysters", 
    "pad_thai", "paella", "pancakes", "panna_cotta", "peking_duck", 
    "pho", "pizza", "pork_chop", "poutine", "prime_rib", 
    "pulled_pork_sandwich", "ramen", "ravioli", "red_velvet_cake", "risotto", 
    "samosa", "sashimi", "scallops", "seaweed_salad", "shrimp_and_grits", 
    "spaghetti_bolognese", "spaghetti_carbonara", "spring_rolls", "steak", "strawberry_shortcake", 
    "sushi", "tacos", "takoyaki", "tiramisu", "tuna_tartare", 
    "waffles"
]

# Glycemic index estimates for different food types
# These are approximate values - ideally you would use a more comprehensive database
glycemic_index_estimates = {
    "high_carb_dessert": {"gi": 70, "impact": "High glycemic impact due to sugar content and refined flour."},
    "pasta_dish": {"gi": 55, "impact": "Moderate glycemic impact. Whole grain versions have lower impact."},
    "meat_dish": {"gi": 10, "impact": "Low glycemic impact. Protein-rich foods have minimal effect on blood glucose."},
    "seafood_dish": {"gi": 10, "impact": "Low glycemic impact. Protein-rich foods have minimal effect on blood glucose."},
    "vegetable_dish": {"gi": 25, "impact": "Low glycemic impact. High fiber content helps slow glucose absorption."},
    "rice_dish": {"gi": 65, "impact": "Moderate to high glycemic impact depending on the rice type."},
    "bread_based": {"gi": 60, "impact": "Moderate to high glycemic impact. Whole grain options have lower impact."},
    "fruit_based": {"gi": 40, "impact": "Moderate glycemic impact. Natural sugars with fiber slow absorption."},
    "soup": {"gi": 35, "impact": "Low to moderate glycemic impact depending on ingredients."},
    "fried_food": {"gi": 55, "impact": "Moderate glycemic impact. Fat content may slow absorption but can affect insulin sensitivity."}
}

# Map food categories to food types for glycemic index estimation
food_type_mapping = {
    # Desserts and sweet items
    "apple_pie": "high_carb_dessert",
    "baklava": "high_carb_dessert",
    "carrot_cake": "high_carb_dessert",
    "cheesecake": "high_carb_dessert",
    "chocolate_cake": "high_carb_dessert",
    "chocolate_mousse": "high_carb_dessert",
    "churros": "high_carb_dessert",
    "cup_cakes": "high_carb_dessert",
    "donuts": "high_carb_dessert",
    "ice_cream": "high_carb_dessert",
    "macarons": "high_carb_dessert",
    "panna_cotta": "high_carb_dessert",
    "red_velvet_cake": "high_carb_dessert",
    "strawberry_shortcake": "high_carb_dessert",
    "tiramisu": "high_carb_dessert",
    "waffles": "high_carb_dessert",
    "pancakes": "high_carb_dessert",
    "french_toast": "high_carb_dessert",
    
    # Pasta dishes
    "lasagna": "pasta_dish",
    "macaroni_and_cheese": "pasta_dish",
    "ravioli": "pasta_dish",
    "spaghetti_bolognese": "pasta_dish",
    "spaghetti_carbonara": "pasta_dish",
    "gnocchi": "pasta_dish",
    
    # Meat dishes
    "baby_back_ribs": "meat_dish",
    "beef_carpaccio": "meat_dish",
    "beef_tartare": "meat_dish",
    "chicken_curry": "meat_dish",
    "chicken_quesadilla": "meat_dish",
    "chicken_wings": "meat_dish",
    "filet_mignon": "meat_dish",
    "pork_chop": "meat_dish",
    "prime_rib": "meat_dish",
    "pulled_pork_sandwich": "meat_dish",
    "steak": "meat_dish",
    
    # Seafood dishes
    "fish_and_chips": "seafood_dish",
    "grilled_salmon": "seafood_dish",
    "lobster_bisque": "seafood_dish",
    "lobster_roll_sandwich": "seafood_dish",
    "mussels": "seafood_dish",
    "oysters": "seafood_dish",
    "sashimi": "seafood_dish",
    "scallops": "seafood_dish",
    "shrimp_and_grits": "seafood_dish",
    "tuna_tartare": "seafood_dish",
    
    # Vegetable dishes
    "beet_salad": "vegetable_dish",
    "caesar_salad": "vegetable_dish",
    "caprese_salad": "vegetable_dish",
    "edamame": "vegetable_dish",
    "greek_salad": "vegetable_dish",
    "seaweed_salad": "vegetable_dish",
    
    # Rice dishes
    "bibimbap": "rice_dish",
    "fried_rice": "rice_dish",
    "paella": "rice_dish",
    "risotto": "rice_dish",
    
    # Bread-based items
    "bruschetta": "bread_based",
    "club_sandwich": "bread_based",
    "garlic_bread": "bread_based",
    "grilled_cheese_sandwich": "bread_based",
    
    # Soups
    "clam_chowder": "soup",
    "french_onion_soup": "soup",
    "hot_and_sour_soup": "soup",
    "miso_soup": "soup",
    "pho": "soup",
    "ramen": "soup",
    
    # Fried foods
    "french_fries": "fried_food",
    "fried_calamari": "fried_food",
    "onion_rings": "fried_food",
    
    # Additional mappings for remaining items
    "ceviche": "seafood_dish",
    "cheese_plate": "bread_based",
    "crab_cakes": "seafood_dish",
    "croque_madame": "bread_based",
    "deviled_eggs": "meat_dish",
    "eggs_benedict": "meat_dish",
    "escargots": "seafood_dish",
    "falafel": "vegetable_dish",
    "foie_gras": "meat_dish",
    "frozen_yogurt": "high_carb_dessert",
    "guacamole": "vegetable_dish",
    "gyoza": "meat_dish",
    "hamburger": "meat_dish",
    "hot_dog": "meat_dish",
    "huevos_rancheros": "meat_dish",
    "hummus": "vegetable_dish",
    "nachos": "bread_based",
    "omelette": "meat_dish",
    "pad_thai": "rice_dish",
    "peking_duck": "meat_dish",
    "poutine": "fried_food",
    "samosa": "fried_food",
    "spring_rolls": "fried_food",
    "sushi": "rice_dish",
    "tacos": "bread_based",
    "takoyaki": "seafood_dish",
    "bread_pudding": "high_carb_dessert",
    "breakfast_burrito": "bread_based",
    "cannoli": "high_carb_dessert",
    "dumplings": "bread_based",
    "beignets": "high_carb_dessert"
}

# Function to get nutritional data from Open Food Facts
def get_nutrition_from_off(food_name):
    # Replace underscores with spaces for better search results
    search_term = food_name.replace('_', ' ')
    
    try:
        response = requests.get(
            f"https://world.openfoodfacts.org/cgi/search.pl?search_terms={search_term}&search_simple=1&action=process&json=1&page_size=1"
        )
        data = response.json()
        
        if data["products"]:
            product = data["products"][0]
            nutrients = {}
            
            if "nutriments" in product:
                for key, value in product["nutriments"].items():
                    if isinstance(value, (int, float)):
                        nutrients[key] = value
            
            calories = product["nutriments"].get("energy-kcal_100g", 0) if "nutriments" in product else 0
            description = product.get("product_name", f"{search_term.title()}")
            
            return {
                "calories": calories,
                "nutrients": nutrients,
                "description": description
            }
    except Exception as e:
        print(f"Error fetching data for {food_name} from Open Food Facts: {e}")
    
    # Return default values if API call fails
    return {
        "calories": 0,
        "nutrients": {},
        "description": f"{search_term.title()}"
    }

# Function to get nutritional data from USDA (requires API key)
def get_nutrition_from_usda(food_name, api_key):
    # Replace underscores with spaces for better search results
    search_term = food_name.replace('_', ' ')
    
    try:
        response = requests.get(
            f"https://api.nal.usda.gov/fdc/v1/foods/search?query={search_term}&dataType=Foundation,SR%20Legacy&pageSize=1&api_key={api_key}"
        )
        data = response.json()
        
        if data["foods"]:
            food_data = data["foods"][0]
            nutrients = {}
            
            for nutrient in food_data["foodNutrients"]:
                nutrient_name = nutrient["nutrientName"].lower().replace(" ", "_")
                if "value" in nutrient:
                    nutrients[nutrient_name] = nutrient["value"]
            
            calories = next((n["value"] for n in food_data["foodNutrients"] 
                           if n["nutrientName"] == "Energy" and "value" in n), 0)
            
            return {
                "calories": calories,
                "nutrients": nutrients,
                "description": food_data["description"]
            }
    except Exception as e:
        print(f"Error fetching data for {food_name} from USDA: {e}")
    
    # Return None if API call fails
    return None

# Create the nutrients database
def create_food101_nutrients_db(usda_api_key=None):
    nutrients_db = {}
    
    for food in food101_categories:
        print(f"Processing {food}...")
        
        # Try to get data from USDA if API key is provided
        usda_data = None
        if usda_api_key:
            usda_data = get_nutrition_from_usda(food, usda_api_key)
            # Add a small delay to avoid hitting API rate limits
            time.sleep(0.5)
        
        # If USDA data is not available, try Open Food Facts
        if not usda_data:
            off_data = get_nutrition_from_off(food)
        else:
            off_data = usda_data
        
        # Get glycemic index information
        food_type = food_type_mapping.get(food, "bread_based")  # Default to bread_based if not found
        gi_data = glycemic_index_estimates.get(food_type, {"gi": 50, "impact": "Moderate glycemic impact."})
        
        # Create entry for this food
        nutrients_db[food] = {
            "calories": off_data["calories"],
            "nutrients": off_data["nutrients"],
            "glycemic_index": gi_data["gi"],
            "portion_size": "1 serving",
            "description": off_data["description"],
            "diabetes_impact": gi_data["impact"]
        }
    
    # Save the nutrients database
    db_file_path = 'food_nutrients_db.json'
    with open(db_file_path, 'w') as f:
        json.dump(nutrients_db, f, indent=4)
    
    print(f"Enhanced nutrients database created successfully with {len(nutrients_db)} food items")
    return nutrients_db

# Check if the database file already exists
def main():
    db_file_path = 'food_nutrients_db.json'
    
    # Check if the database file already exists
    if os.path.exists(db_file_path):
        print(f"Database file '{db_file_path}' already exists. Skipping database creation.")
        print("To recreate the database, delete the existing file and run this script again.")
        return
    
    # Create the database if it doesn't exist
    print(f"Database file '{db_file_path}' not found. Creating new database...")
    
    # Get API key from environment variable for security
    usda_api_key = os.environ.get('USDA_API_KEY')
    if usda_api_key:
        print(f"USDA API key found in environment variables. Using USDA FoodData Central API.")
        create_food101_nutrients_db(usda_api_key=usda_api_key)
    else:
        print("No USDA API key found in environment variables. Using Open Food Facts API only.")
        create_food101_nutrients_db()

# Run the main function
if __name__ == "__main__":
    main()
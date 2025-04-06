import json

nutrients_db = {
    "pizza": {
        "calories": 266,
        "nutrients": {
            "carbohydrates": 33.0,
            "protein": 11.0,
            "fat": 10.0,
            "fiber": 2.3,
            "sugar": 3.6
        },
        "description": "Pizza with cheese, tomato sauce, and various toppings"
    },
    "salad": {
        "calories": 152,
        "nutrients": {
            "carbohydrates": 11.0,
            "protein": 3.8,
            "fat": 11.0,
            "fiber": 3.0,
            "sugar": 2.5
        },
        "description": "Mixed greens with vegetables and dressing"
    },
    "sandwich": {
        "calories": 290,
        "nutrients": {
            "carbohydrates": 38.0,
            "protein": 15.0,
            "fat": 9.0,
            "fiber": 2.0,
            "sugar": 4.0
        },
        "description": "Sandwich with bread, meat, cheese, and vegetables"
    }
}

with open('food_nutrients_db.json', 'w') as f:
    json.dump(nutrients_db, f, indent=4)

print('Nutrients database created successfully')
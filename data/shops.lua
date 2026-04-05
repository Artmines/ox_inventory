  return {
      General = {
          name = 'General Store',
          blip = { id = 52, colour = 69, scale = 0.4 },
          inventory = {
              { name = 'sandwich',       price = 3   },
              { name = 'sandwich_egg',   price = 3   },
              { name = 'water',          price = 3   },
              { name = 'bandage',        price = 50  },
              { name = 'cigarette_pack', price = 20  },
              { name = 'coffee',         price = 295 },
              { name = 'soda',           price = 25  },
              { name = 'energy_pepe',    price = 110 },
              { name = 'chocolate_bar',  price = 25  },
              { name = 'donut',          price = 105 },
              { name = 'crisp',          price = 25  },
              { name = 'rolling_paper',  price = 20  },
          },
          locations = {
              vec3(-47.055,   -1758.926, 28.421),
              vec3(24.299,    -1347.754, 28.497),
              vec3(812.788,   -782.145,  25.175),
              vec3(-706.170,  -914.450,  18.220),
              vec3(-548.526,  -582.987,  33.682),
              vec3(1164.832,  -323.686,  68.205),
              vec3(372.375,   325.974,   102.566),
              vec3(-1819.493, 793.468,   137.086),
              vec3(-3241.760, 999.744,   11.830),
              vec3(-3038.401, 584.503,   6.909),
              vec3(549.138,   2671.834,  41.156),
              vec3(1960.242,  3739.443,  31.344),
              vec3(2678.515,  3279.066,  54.241),
              vec3(2557.883,  380.803,   107.623),
              vec3(1697.360,  4923.383,  41.064),
              vec3(1727.500,  6414.857,  34.037),
          },
      },

      HospitalCafe = {
          name = 'Hospital Café',
          blip = { id = 52, colour = 69, scale = 0.4 },
          inventory = {
              { name = 'firstaid',     price = 250 },
              { name = 'bandage',      price = 50  },
              { name = 'water',        price = 3   },
              { name = 'sandwich_blt', price = 5   },
              { name = 'coffee',       price = 295 },
          },
          locations = { vec3(86.613, -394.750, 38.378) },
      },

      Liquor = {
          name = 'Liquor Store',
          blip = { id = 52, colour = 64, scale = 0.4 },
          inventory = {
              { name = 'vodka',          price = 150 },
              { name = 'beer',           price = 100 },
              { name = 'water',          price = 3   },
              { name = 'bandage',        price = 50  },
              { name = 'cigarette_pack', price = 20  },
              { name = 'coffee',         price = 295 },
              { name = 'soda',           price = 25  },
              { name = 'energy_pepe',    price = 110 },
              { name = 'chocolate_bar',  price = 25  },
              { name = 'donut',          price = 105 },
              { name = 'crisp',          price = 25  },
              { name = 'rolling_paper',  price = 20  },
          },
          locations = {
              vec3(-2966.381, 391.449,  14.043),
              vec3(-1486.740, -377.561, 39.163),
              vec3(1134.331,  -983.138, 45.416),
              vec3(-1221.469, -907.976, 11.326),
          },
      },

      Ammunation = {
          name = 'Ammunation',
          blip = { id = 110, colour = 6, scale = 0.45 },
          inventory = {
              { name = 'armor',        price = 750  },
              { name = 'heavyarmor',   price = 2250 },
              { name = 'WEAPON_PISTOL',price = 0,   license = 'weapon' },
              { name = 'WEAPON_FNX',   price = 0,   license = 'weapon' },
              { name = 'AMMO_PISTOL',  price = 0   },
              { name = 'WEAPON_BAT',   price = 0   },
          },
          locations = {
              vec3(18.009,    -1107.660, 28.797),
              vec3(-659.143,  -939.415,  20.829),
              vec3(-544.952,  -584.108,  33.682),
              vec3(813.790,   -2155.183, 28.619),
              vec3(-326.378,  6081.514,  30.455),
              vec3(1697.864,  3757.567,  33.705),
              vec3(2564.758,  298.400,   107.735),
              vec3(-1310.348, -394.368,  35.696),
              vec3(247.459,   -51.610,   68.941),
              vec3(841.177,   -1029.037, 27.195),
              vec3(-1112.734, 2697.436,  17.554),
          },
      },

      Hardware = {
          name = 'Hardware Store',
          blip = { id = 566, colour = 28, scale = 0.4 },
          inventory = {
              { name = 'screwdriver',           price = 400  },
              { name = 'WEAPON_HAMMER',         price = 0    },
              { name = 'WEAPON_CROWBAR',        price = 0    },
              { name = 'WEAPON_GOLFCLUB',       price = 0    },
              { name = 'repairkit',             price = 350  },
              { name = 'fertilizer_nitrogen',   price = 600  },
              { name = 'fertilizer_phosphorus', price = 600  },
              { name = 'fertilizer_potassium',  price = 600  },
              { name = 'plastic_wrap',          price = 50   },
              { name = 'baggy',                 price = 50   },
              { name = 'binoculars',            price = 90   },
              { name = 'WEAPON_SHOVEL',         price = 0    },
              { name = 'cloth',                 price = 4    },
              { name = 'pipe',                  price = 12   },
              { name = 'nails',                 price = 2    },
              { name = 'drill',                 price = 5000 },
          },
          locations = {
              vec3(46.131,   -1749.423, 28.639),
              vec3(2747.878, 3472.742,  54.673),
          },
      },

      MedicalSupplies = {
          name = 'Medical Supplies',
          inventory = {
              { name = 'traumakit',  price = 500  },
              { name = 'medicalkit', price = 1000 },
              { name = 'firstaid',   price = 250  },
              { name = 'bandage',    price = 50   },
              { name = 'morphine',   price = 600  },
              { name = 'radio',      price = 725  },
              { name = 'phone',      price = 100  },
              { name = 'scuba_gear', price = 1000 },
          },
          locations = {
              vec3(310.098, -568.282, 42.284),
              vec3(51.918,  -387.304, 38.378),
          },
      },

      Pharmacy = {
          name = 'Pharmacy',
          inventory = {
              { name = 'firstaid',     price = 250 },
              { name = 'bandage',      price = 50  },
              { name = 'water',        price = 3   },
              { name = 'sandwich_blt', price = 5   },
          },
          locations = { vec3(75.437, -363.061, 38.378) },
      },

      DigitalDen = {
          name = 'Digital Den',
          inventory = {
              { name = 'phone',           price = 100  },
              { name = 'radio_shitty',    price = 2500 },
              { name = 'camera',          price = 200  },
              { name = 'electronics_kit', price = 0    },
          },
          locations = { vec3(392.410, -832.409, 28.292) },
      },

      FoodWholesaler = {
          name = 'Food Wholesaler',
          blip = { id = 90, colour = 69, scale = 0.4 },
          inventory = {
              { name = 'dough',             price = 0 },
              { name = 'eggs',              price = 0 },
              { name = 'loaf',              price = 0 },
              { name = 'sugar',             price = 0 },
              { name = 'flour',             price = 0 },
              { name = 'rice',              price = 0 },
              { name = 'icing',             price = 0 },
              { name = 'milk_can',          price = 0 },
              { name = 'tea_leaf',          price = 0 },
              { name = 'plastic_cup',       price = 0 },
              { name = 'coffee_beans',      price = 0 },
              { name = 'bun',               price = 0 },
              { name = 'water',             price = 3 },
              { name = 'cheese',            price = 0 },
              { name = 'rum',               price = 0 },
              { name = 'whiskey',           price = 0 },
              { name = 'tequila',           price = 0 },
              { name = 'keg',               price = 0 },
          },
          locations = { vec3(1994.428, 3778.962, 31.181) },
      },

      SmokeOnTheWater = {
          name = 'Smoke on the Water',
          inventory = {
              { name = 'weed_joint',    price = 25 },
              { name = 'rolling_paper', price = 20 },
          },
          locations = { vec3(-1161.047, -1576.581, 3.301) },
      },

      Winery = {
          name = 'Winery',
          inventory = {
              { name = 'wine_bottle', price = 300 },
          },
          locations = { vec3(-1911.636, 2074.202, 139.387) },
      },

      -- special shops opened programmatically (no locations, no markers)
      ['shop:hunting-supplies'] = {
          name = 'Hunting Supplies',
          inventory = {
              { name = 'WEAPON_SNIPERRIFLE2', price = 0  },
              { name = 'AMMO_SNIPER',         price = 0  },
              { name = 'WEAPON_KNIFE',        price = 0  },
              { name = 'hunting_bait',        price = 10 },
          },
      },
      ['shop:fishing-supplies'] = {
          name = 'Fishing Supplies',
          inventory = {
              { name = 'fishing_rod',          price = 750 },
              { name = 'fishing_bait_worm',    price = 15  },
              { name = 'fishing_bait_lugworm', price = 10  },
              { name = 'WEAPON_KNIFE',         price = 0   },
          },
      },
      ['shop:fishing-supplies-advanced'] = {
          name = 'Advanced Fishing Supplies',
          inventory = {
              { name = 'fishing_rod',          price = 750  },
              { name = 'fishing_net',          price = 3000 },
              { name = 'fishing_bait_worm',    price = 15   },
              { name = 'fishing_bait_lugworm', price = 10   },
              { name = 'WEAPON_KNIFE',         price = 0    },
          },
      },
      ['shop:doj-shop'] = {
          name = 'DOJ Shop',
          inventory = {
              { name = 'personal_plates', price = 5000 },
          },
      },
      ['shop:vending-water']  = { name = 'Water Machine',          inventory = { { name = 'water',        price = 3
     } } },
      ['shop:vending-coffee'] = { name = 'Coffee Machine',         inventory = { { name = 'coffee',       price =
  295 } } },
      ['shop:vending-drinks'] = { name = 'Drinks Vending Machine', inventory = { { name = 'water', price = 3 }, {
  name = 'soda', price = 25 }, { name = 'energy_pepe', price = 110 } } },
      ['shop:vending-food']   = { name = 'Food Vending Machine',   inventory = { { name = 'chocolate_bar', price =
  25 }, { name = 'donut', price = 105 }, { name = 'crisp', price = 25 } } },
      ['shop:fuel-pump']      = { name = 'Fuel Pump',              inventory = { { name = 'WEAPON_PETROLCAN', price
   = 0 } } },
  }


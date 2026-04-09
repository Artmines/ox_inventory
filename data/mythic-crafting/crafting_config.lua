return {
	{
		label = "Salvage Exchange",
		targetConfig = {
			actionString = "Trading",
			icon = "business-time",
			ped = {
				model = "s_m_m_gardener_01",
				task = "WORLD_HUMAN_LEANING",
			},
		},
		location = {
			x = 2350.925,
			y = 3145.093,
			z = 47.209,
			h = 169.500,
		},
		restriction = {
			shared = true,
		},
		recipes = {
			{
				result = { name = "ironbar", count = 10 },
				items = {
					{ name = "salvagedparts", count = 25 },
				},
				time = 0,
			},
			{
				result = { name = "scrapmetal", count = 20 },
				items = {
					{ name = "salvagedparts", count = 10 },
				},
				time = 0,
			},
			{
				result = { name = "heavy_glue", count = 20 },
				items = {
					{ name = "salvagedparts", count = 10 },
				},
				time = 0,
			},
			{
				result = { name = "rubber", count = 16 },
				items = {
					{ name = "salvagedparts", count = 8 },
				},
				time = 0,
			},
			{
				result = { name = "plastic", count = 6 },
				items = {
					{ name = "salvagedparts", count = 3 },
				},
				time = 0,
			},
			{
				result = { name = "copperwire", count = 4 },
				items = {
					{ name = "salvagedparts", count = 2 },
				},
				time = 0,
			},
			{
				result = { name = "glue", count = 4 },
				items = {
					{ name = "salvagedparts", count = 2 },
				},
				time = 0,
			},
			{
				result = { name = "electronic_parts", count = 32 },
				items = {
					{ name = "salvagedparts", count = 8 },
				},
				time = 0,
			},
		},
	},
	{
        label = "Crafting Bench",
        targetConfig = {
            actionString = "Crafting",
            icon = "hammer",
            model = "gr_prop_gr_bench_02b",
        },
        location = {
            x = -478.240,
            y = -1667.160,
            z = 17.700,
            h = 333.325,
        },
        restriction = {
            shared = true,
        --    schematics = true,
        },
        recipes = {
            {
                result = { name = "thermite", count = 1 },
                items = {
                    { name = "ironbar", count = 200 },
                    { name = "electronic_parts", count = 150 },
                    { name = "copperwire", count = 200 },
                    { name = "heavy_glue", count = 300 },
                },
                time = 5000,
                animation = "mechanic",
            },
            {
                result = { name = "adv_electronics_kit", count = 1 },
                items = {
                    { name = "goldbar", count = 1 },
                    { name = "silverbar", count = 2 },
                    { name = "electronic_parts", count = 30 },
                    { name = "heavy_glue", count = 5 },
                    { name = "plastic", count = 30 },
                    { name = "copperwire", count = 20 },
                },
                time = 5000,
                animation = "mechanic",
            },
            {
                result = { name = "handcuffs", count = 1 },
                items = {
                    { name = "ironbar", count = 20 },
                },
                time = 5000,
                animation = "mechanic",
            },
        },
    },
	{
		label = "Recycle Exchange",
		targetConfig = {
			actionString = "Trading",
			icon = "business-time",
			ped = {
				model = "s_m_m_dockwork_01",
				task = "WORLD_HUMAN_JANITOR",
			},
		},
		location = {
			x = -334.833,
			y = -1577.247,
			z = 24.222,
			h = 20.715,
		},
		restriction = {
			shared = true,
		},
		recipes = {
			{
				result = { name = "ironbar", count = 10 },
				items = {
					{ name = "recycledgoods", count = 25 },
				},
				time = 0,
			},
			{
				result = { name = "scrapmetal", count = 20 },
				items = {
					{ name = "recycledgoods", count = 10 },
				},
				time = 0,
			},
			{
				result = { name = "heavy_glue", count = 20 },
				items = {
					{ name = "recycledgoods", count = 10 },
				},
				time = 0,
			},
			{
				result = { name = "rubber", count = 16 },
				items = {
					{ name = "recycledgoods", count = 8 },
				},
				time = 0,
			},
			{
				result = { name = "plastic", count = 6 },
				items = {
					{ name = "recycledgoods", count = 3 },
				},
				time = 0,
			},
			{
				result = { name = "copperwire", count = 4 },
				items = {
					{ name = "recycledgoods", count = 2 },
				},
				time = 0,
			},
			{
				result = { name = "glue", count = 4 },
				items = {
					{ name = "recycledgoods", count = 2 },
				},
				time = 0,
			},
		},
	},
	{
		label = "Smelter",
		targetConfig = {
			actionString = "Smelting",
			icon = "fire-burner",
			model = "gr_prop_gr_bench_02b",
		},
		location = {
			x = 1112.165,
			y = -2030.834,
			z = 29.914,
			h = 235.553,
		},
		restriction = {
			shared = true,
		},
		recipes = {
			{
				result = { name = "goldbar", count = 1 },
				items = {
					{ name = "goldore", count = 1 },
				},
				time = 5000,
				animation = "mechanic",
			},
			{
				result = { name = "silverbar", count = 1 },
				items = {
					{ name = "silverore", count = 1 },
				},
				time = 5000,
				animation = "mechanic",
			},
			{
				result = { name = "ironbar", count = 3 },
				items = {
					{ name = "ironore", count = 1 },
				},
				time = 5000,
				animation = "mechanic",
			},
		},
	},
	{
		label = "Sign Exchange",
		targetConfig = {
			icon = "hand-middle-finger",
			ped = {
				model = "s_m_y_ammucity_01",
				task = "WORLD_HUMAN_CLIPBOARD",
			},
		},
		location = {
			x = 1746.624,
			y = 3688.159,
			z = 33.334,
			h = 343.688,
		},
		restriction = {
			shared = true,
			rep = {
				id = "SignRobbery",
				level = 16000,
			},
		},
		recipes = {
			{
				result = { name = "ironbar", count = 50 },
				items = {
					{ name = "sign_dontblock", count = 5 },
					{ name = "sign_leftturn", count = 5 },
					{ name = "sign_nopark", count = 5 },
					{ name = "sign_notresspass", count = 5 },
				},
			},
			{
				result = { name = "scrapmetal", count = 75 },
				items = {
					{ name = "sign_rightturn", count = 5 },
					{ name = "sign_stop", count = 5 },
					{ name = "sign_uturn", count = 5 },
					{ name = "sign_walkingman", count = 5 },
					{ name = "sign_yield", count = 5 },
				},
			},
		},
	},
}

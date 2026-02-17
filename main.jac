"""PriceComparator - A multi-user price comparison app with AI-powered analysis."""

cl {
    import from frontend { app as ClientApp }

    def:pub app {
        return <ClientApp />;
    }
}

import from byllm.lib { Model }
import from uuid { uuid4 }

glob llm = Model(model_name="gemini/gemini-2.5-flash");

# --- AI Types ---

enum ProductCategory { PRODUCTIVITY, ELECTRONICS, GROCERIES, CLOTHING, HOME, HEALTH, BEAUTY, BABY, CHILDREN, OTHER }
enum PriceRange { BUDGET, MODERATE, PREMIUM, LUXURY }

obj PriceAnalysis {
    has best_store: str;
    has worst_store: str;
    has avg_price: float;
    has recommendation: str;
}

sem PriceAnalysis.recommendation = "A brief recommendation on where to buy based on price comparison";

"""Categorize a product based on its name."""
def categorize_product(product_name: str) -> ProductCategory by llm();

"""Determine the price range category of a product based on its price."""
def classify_price_range(price: float, product_name: str) -> PriceRange by llm();

"""Analyze price data and provide recommendation."""
def analyze_prices(product_name: str, store_prices: list[dict]) -> PriceAnalysis by llm();

# --- Data Nodes ---

node Product {
    has id: str,
        name: str,
        category: str = "other";
}

node Store {
    has name: str,
        price: float,
        last_updated: str = "",
        available: bool = True,
        url: str = "";
}

# NEW: A standalone global store entry, independent of any product.
# Lives directly under Root so users can build a reusable list of stores.
node StoreEntry {
    has id: str,
        name: str;
}

# --- Product Walkers (unchanged) ---

walker:priv AddProduct {
    has title: str;

    can create with Root entry {
        category = str(categorize_product(self.title)).split(".")[-1].lower();
        
        new_product = here ++> Product(
            id=str(uuid4()),
            name=self.title,
            category=category
        );
        report {
            "id": new_product[0].id,
            "name": new_product[0].name,
            "category": new_product[0].category
        };
    }
}

walker:priv ListProducts {
    has products: list = [];

    can collect with Root entry {
        visit [-->];
    }

    can gather with Product entry {
        self.products.append({
            "id": here.id,
            "name": here.name,
            "category": here.category
        });
    }

    can report_all with Root exit {
        report self.products;
    }
}

walker:priv DeleteProduct {
    has product_id: str;

    can search with Root entry {
        visit [-->];
    }

    can delete with Product entry {
        if here.id == self.product_id {
            del here;
            report {"deleted": self.product_id};
        }
    }
}

# --- Store Price Walkers (unchanged) ---

walker:priv AddStorePrice {
    has product_id: str;
    has store_name: str;
    has price: float;
    has url: str = "";
    has last_updated: str = "";

    can search with Root entry {
        visit [-->];
    }

    can add_store with Product entry {
        if here.id == self.product_id {
            here ++> Store(
                name=self.store_name,
                price=self.price,
                available=True,
                url=self.url,
                last_updated=self.last_updated
            );
            report {
                "product_id": here.id,
                "store": self.store_name,
                "price": self.price
            };
        }
    }
}

walker:priv ListStorePrices {
    has product_id: str;
    has stores: list = [];

    can search with Root entry {
        visit [-->];
    }

    can collect with Product entry {
        if here.id == self.product_id {
            visit [-->];
        }
    }

    can gather with Store entry {
        self.stores.append({
            "name": here.name,
            "price": here.price,
            "available": here.available,
            "url": here.url,
            "last_updated": here.last_updated
        });
    }

    can report_all with Root exit {
        report self.stores;
    }
}

walker:priv UpdateStorePrice {
    has product_id: str;
    has store_name: str;
    has price: float;
    has last_updated: str = "";

    can search with Root entry {
        visit [-->];
    }

    can find_product with Product entry {
        if here.id == self.product_id {
            visit [-->];
        }
    }

    can update with Store entry {
        if here.name == self.store_name {
            here.price = self.price;
            here.last_updated = self.last_updated;
            report {
                "store": here.name,
                "price": here.price,
                "updated": True
            };
        }
    }
}

walker:priv DeleteStore {
    has product_id: str;
    has store_name: str;

    can search with Root entry {
        visit [-->];
    }

    can find_product with Product entry {
        if here.id == self.product_id {
            visit [-->];
        }
    }

    can delete with Store entry {
        if here.name == self.store_name {
            del here;
            report {"deleted": self.store_name};
        }
    }
}

walker:priv GetBestPrice {
    has product_id: str;
    has stores: list = [];

    can search with Root entry {
        visit [-->];
    }

    can find_product with Product entry {
        if here.id == self.product_id {
            visit [-->];
        }
    }

    can collect with Store entry {
        self.stores.append({
            "name": here.name,
            "price": here.price,
            "available": here.available,
            "url": here.url
        });
    }

    can analyze with Root exit {
        if len(self.stores) > 0 {
            available_stores = [s for s in self.stores if s["available"]];
            if len(available_stores) > 0 {
                best = available_stores[0];
                for store in available_stores {
                    if store["price"] < best["price"] {
                        best = store;
                    }
                }
                report {
                    "best_store": best["name"],
                    "best_price": best["price"],
                    "url": best["url"],
                    "all_stores": available_stores
                };
            } else {
                report {"error": "No available stores"};
            }
        } else {
            report {"error": "No stores found"};
        }
    }
}

walker:priv ComparePrices {
    has product_id: str;
    has product_name: str = "";
    has stores: list = [];

    can search with Root entry {
        visit [-->];
    }

    can find_product with Product entry {
        if here.id == self.product_id {
            self.product_name = here.name;
            visit [-->];
        }
    }

    can collect with Store entry {
        self.stores.append({
            "name": here.name,
            "price": here.price
        });
    }

    can analyze with Root exit {
        if len(self.stores) > 0 and self.product_name {
            analysis = analyze_prices(self.product_name, self.stores);
            report {
                "best_store": analysis.best_store,
                "worst_store": analysis.worst_store,
                "avg_price": analysis.avg_price,
                "recommendation": analysis.recommendation,
                "stores": self.stores
            };
        } else {
            report {"error": "No data for comparison"};
        }
    }
}

# --- Global Store List Walkers (NEW) ---
# These three walkers manage the user's personal list of stores.
# They are completely independent of Products and Store price nodes.

walker:priv AddStoreEntry {
    has name: str;

    can create with Root entry {
        new_entry = here ++> StoreEntry(
            id=str(uuid4()),
            name=self.name
        );
        report {
            "id": new_entry[0].id,
            "name": new_entry[0].name
        };
    }
}

walker:priv ListStoreEntries {
    has entries: list = [];

    can collect with Root entry {
        visit [-->];
    }

    can gather with StoreEntry entry {
        self.entries.append({
            "id": here.id,
            "name": here.name
        });
    }

    can report_all with Root exit {
        report self.entries;
    }
}

walker:priv DeleteStoreEntry {
    has store_id: str;

    can search with Root entry {
        visit [-->];
    }

    can delete with StoreEntry entry {
        if here.id == self.store_id {
            del here;
            report {"deleted": self.store_id};
        }
    }
}

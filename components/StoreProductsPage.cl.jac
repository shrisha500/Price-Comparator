"""StoreProductsPage — manage products available at a specific store."""

sv import from main { AddProduct, ListProducts, DeleteProduct }

def:pub StoreProductsPage(
    store: dict,      # the StoreEntry object { id, name }
    onBack: any       # callback to navigate back to home
) -> obj {
    has storeProducts: list = [],
        newProductName: str = "",
        productsLoading: bool = True,
        searchQuery: str = "";

    can with entry {
        loadProducts();
    }

    async def loadProducts -> None;
    async def addStoreProduct -> None;
    async def deleteStoreProduct(productId: str) -> None;
    def handleKeyPress(e: any) -> None;
    def filteredProducts -> list;

    filteredList = filteredProducts();

    return
        <div className="app-container">
            <div className="app-content">
                # --- Header with Back button ---
                <div className="card">
                    <div className="card-header">
                        <div style={{"display": "flex", "alignItems": "center", "gap": "1rem"}}>
                            <button
                                onClick={onBack}
                                className="btn-signout"
                                style={{"fontSize": "1.2rem", "padding": "0.4rem 0.8rem"}}
                                title="Back to home"
                            >
                                ← Back
                            </button>
                            <div>
                                <h1 className="app-title" style={{"fontSize": "1.5rem"}}>
                                    🏪 {store.name}
                                </h1>
                                <p className="app-subtitle">Products tracked at this store</p>
                            </div>
                        </div>
                    </div>
                </div>

                <div className="card">
                    <h2 className="panel-title">Add Product</h2>
                    <div className="add-row">
                        <input
                            type="text"
                            value={newProductName}
                            onChange={lambda e: any -> None { newProductName = e.target.value; }}
                            onKeyPress={handleKeyPress}
                            placeholder="Enter product name to track at {store.name}..."
                            className="todo-input"
                        />
                        <button
                            onClick={lambda -> None { addStoreProduct(); }}
                            className="btn-add"
                        >
                            Add
                        </button>
                    </div>
                </div>

                <div className="card">
                    <h2 className="panel-title">Products</h2>
                    # Search/filter bar
                    <div style={{"marginBottom": "1rem"}}>
                        <input
                            type="text"
                            value={searchQuery}
                            onChange={lambda e: any -> None { searchQuery = e.target.value; }}
                            placeholder="Search products..."
                            className="todo-input"
                            style={{"width": "100%"}}
                        />
                    </div>

                    {(
                        <div className="loading-message">Loading products...</div>
                    ) if productsLoading else (
                        <div>
                            {(
                                <div className="empty-message">
                                    No products yet. Add one above!
                                </div>
                            ) if filteredList.length == 0 else (
                                <div>
                                    {[
                                        <div
                                            key={product.id}
                                            className="ingredient-item"
                                            style={{"justifyContent": "space-between"}}
                                        >
                                            <div className="ingredient-info">
                                                <span className="ingredient-name">{product.name}</span>
                                                <span className="category-badge" style={{
                                                    "fontSize": "0.75rem",
                                                    "padding": "0.25rem 0.5rem",
                                                    "borderRadius": "4px",
                                                    "background": "rgba(59,130,246,0.2)",
                                                    "color": "#60a5fa",
                                                    "marginLeft": "0.5rem"
                                                }}>
                                                    {product.category}
                                                </span>
                                            </div>
                                            <button
                                                onClick={lambda -> None { deleteStoreProduct(product.id); }}
                                                className="btn-delete"
                                            >
                                                ×
                                            </button>
                                        </div> for product in filteredList
                                    ]}
                                </div>
                            )}
                        </div>
                    )}
                </div>
            </div>
        </div>;
}

impl StoreProductsPage.loadProducts -> None {
    productsLoading = True;
    result = root spawn ListProducts();
    storeProducts = result.reports[0] if result.reports else [];
    productsLoading = False;
}

impl StoreProductsPage.addStoreProduct -> None {
    if not newProductName.trim() { return; }
    response = root spawn AddProduct(title=newProductName);
    newEntry = response.reports[0];
    storeProducts = storeProducts.concat([{
        "id": newEntry.id,
        "name": newEntry.name,
        "category": newEntry.category
    }]);
    newProductName = "";
}

impl StoreProductsPage.deleteStoreProduct(productId: str) -> None {
    root spawn DeleteProduct(product_id=productId);
    storeProducts = storeProducts.filter(
        lambda p: any -> bool { return p.id != productId; }
    );
}

impl StoreProductsPage.handleKeyPress(e: any) -> None {
    if e.key == "Enter" { addStoreProduct(); }
}

impl StoreProductsPage.filteredProducts -> list {
    if not searchQuery.trim() { return storeProducts; }
    q = searchQuery.toLowerCase();
    return storeProducts.filter(
        lambda p: any -> bool { return p.name.toLowerCase().includes(q); }
    );
}



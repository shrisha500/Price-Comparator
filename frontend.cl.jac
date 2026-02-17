"""Price Comparator - Client-Side UI."""

import from "@jac/runtime" { jacSignup, jacLogin, jacLogout, jacIsLoggedIn }

import "./styles.css";

import from components.ProductItem { ProductItem }
import from components.StoreItem { StoreItem }
import from components.StoreEntryItem { StoreEntryItem }
import from components.AuthForm { AuthForm }

sv import from main {
    AddProduct, ListProducts, DeleteProduct,
    AddStorePrice, ListStorePrices, UpdateStorePrice, DeleteStore,
    GetBestPrice, ComparePrices,
    AddStoreEntry, ListStoreEntries, DeleteStoreEntry
}

def:pub app -> any {
    has isLoggedIn: bool = False,
        checkingAuth: bool = True,
        isSignup: bool = False,
        username: str = "",
        password: str = "",
        error: str = "",
        loading: bool = False,

        # --- Products (unchanged) ---
        products: list = [],
        newProductName: str = "",
        productsLoading: bool = True,
        selectedProductId: str = "",
        selectedProductName: str = "",
        stores: list = [],
        storesLoading: bool = False,
        newStoreName: str = "",
        newStorePrice: str = "",
        newStoreUrl: str = "",
        comparison: any = None,
        comparisonLoading: bool = False,

        # --- Global store list (NEW) ---
        storeEntries: list = [],
        newStoreEntryName: str = "",
        storeEntriesLoading: bool = True;

    can with entry {
        isLoggedIn = jacIsLoggedIn();
        checkingAuth = False;
    }

    can with [isLoggedIn] entry {
        if isLoggedIn {
            fetchProducts();
            fetchStoreEntries();   # load the store list alongside products
        }
    }

    # --- Method declarations (product, unchanged) ---
    async def fetchProducts -> None;
    async def addProduct -> None;
    async def deleteProduct(productId: str) -> None;
    async def selectProduct(productId: str, productName: str) -> None;
    async def fetchStores(productId: str) -> None;
    async def addStore -> None;
    async def deleteStore(storeName: str) -> None;
    async def compareAllPrices -> None;
    async def handleLogin -> None;
    async def handleSignup -> None;
    def handleLogout -> None;
    async def handleSubmit(e: any) -> None;
    def handleProductKeyPress(e: any) -> None;
    def handleStoreKeyPress(e: any) -> None;
    def getBestPrice -> any;

    # --- Method declarations (store list, NEW) ---
    async def fetchStoreEntries -> None;
    async def addStoreEntry -> None;
    async def deleteStoreEntry(storeId: str) -> None;
    def handleStoreEntryKeyPress(e: any) -> None;

    if checkingAuth {
        return
            <div style={{"display": "flex", "justifyContent": "center",
                         "alignItems": "center", "minHeight": "100vh",
                         "color": "rgba(255,255,255,0.6)", "fontFamily": "system-ui"}}>
                Loading...
            </div>;
    }

    if isLoggedIn {
        bestPrice = getBestPrice();
        return
            <div className="app-container">
                <div className="app-content">
                    <div className="card">
                        <div className="card-header">
                            <div>
                                <h1 className="app-title">PriceComparator</h1>
                                <p className="app-subtitle">
                                    Compare prices across multiple stores with AI insights
                                </p>
                            </div>
                            <button onClick={handleLogout} className="btn-signout">
                                Sign Out
                            </button>
                        </div>
                    </div>
                    <div className="two-column-layout">
                        <div className="column-left">
                            <div className="card">
                                <h2 className="panel-title">Products</h2>
                                <div className="add-row">
                                    <input
                                        type="text"
                                        value={newProductName}
                                        onChange={lambda e: any -> None { newProductName = e.target.value; }}
                                        onKeyPress={handleProductKeyPress}
                                        placeholder="Enter product name..."
                                        className="todo-input"
                                    />
                                    <button
                                        onClick={lambda -> None { addProduct(); }}
                                        className="btn-add"
                                    >
                                        Add
                                    </button>
                                </div>
                            </div>
                            <div className="card">
                                {(
                                    <div className="loading-message">Loading products...</div>
                                ) if productsLoading else (
                                    <div>
                                        {(
                                            <div className="empty-message">
                                                No products yet. Add one above!
                                            </div>
                                        ) if products.length == 0 else (
                                            <div>
                                                {[
                                                    <ProductItem
                                                        key={product.id}
                                                        product={product}
                                                        isSelected={product.id == selectedProductId}
                                                        onSelect={selectProduct}
                                                        onDelete={deleteProduct}
                                                    /> for product in products
                                                ]}
                                            </div>
                                        )}
                                    </div>
                                )}
                            </div>
                            <div className="card">
                                <h2 className="panel-title">Stores</h2>
                                <p className="panel-subtitle">Add stores you want to track</p>
                                <div className="add-row">
                                    <input
                                        type="text"
                                        value={newStoreEntryName}
                                        onChange={lambda e: any -> None { newStoreEntryName = e.target.value; }}
                                        onKeyPress={handleStoreEntryKeyPress}
                                        placeholder="Enter store name (e.g. Amazon)..."
                                        className="todo-input"
                                    />
                                    <button
                                        onClick={lambda -> None { addStoreEntry(); }}
                                        className="btn-add"
                                    >
                                        Add
                                    </button>
                                </div>
                            </div>
                            <div className="card">
                                {(
                                    <div className="loading-message">Loading stores...</div>
                                ) if storeEntriesLoading else (
                                    <div>
                                        {(
                                            <div className="empty-message">
                                                No stores yet. Add one above!
                                            </div>
                                        ) if storeEntries.length == 0 else (
                                            <div>
                                                {[
                                                    <StoreEntryItem
                                                        key={store.id}
                                                        store={store}
                                                        onDelete={deleteStoreEntry}
                                                    /> for store in storeEntries
                                                ]}
                                            </div>
                                        )}
                                    </div>
                                )}
                            </div>

                        </div>
                        <div className="column-right">
                            {(
                                <div className="card">
                                    <div className="empty-message">
                                        Select a product to view and compare prices
                                    </div>
                                </div>
                            ) if not selectedProductId else (
                                <div>
                                    <div className="card">
                                        <div style={{"display": "flex", "justifyContent": "space-between", "alignItems": "center", "marginBottom": "1rem"}}>
                                            <div>
                                                <h2 className="panel-title">{selectedProductName}</h2>
                                                <p className="panel-subtitle">Add stores and prices</p>
                                            </div>
                                            <button
                                                onClick={lambda -> None { compareAllPrices(); }}
                                                disabled={comparisonLoading or stores.length < 2}
                                                className="btn-generate"
                                                style={{"fontSize": "0.9rem", "padding": "0.5rem 1rem"}}
                                            >
                                                {("Analyzing..." if comparisonLoading else "Compare All")}
                                            </button>
                                        </div>
                                        <div className="add-row" style={{"gap": "0.5rem", "flexWrap": "wrap"}}>
                                            <input
                                                type="text"
                                                value={newStoreName}
                                                onChange={lambda e: any -> None { newStoreName = e.target.value; }}
                                                placeholder="Store name"
                                                className="todo-input"
                                                style={{"flex": "1", "minWidth": "120px"}}
                                            />
                                            <input
                                                type="number"
                                                step="0.01"
                                                value={newStorePrice}
                                                onChange={lambda e: any -> None { newStorePrice = e.target.value; }}
                                                onKeyPress={handleStoreKeyPress}
                                                placeholder="Price"
                                                className="todo-input"
                                                style={{"width": "100px"}}
                                            />
                                            <input
                                                type="text"
                                                value={newStoreUrl}
                                                onChange={lambda e: any -> None { newStoreUrl = e.target.value; }}
                                                placeholder="URL (optional)"
                                                className="todo-input"
                                                style={{"flex": "1", "minWidth": "150px"}}
                                            />
                                            <button
                                                onClick={lambda -> None { addStore(); }}
                                                className="btn-add"
                                            >
                                                Add
                                            </button>
                                        </div>
                                    </div>
                                    {(
                                        <div className="card">
                                            <div className="comparison-panel">
                                                <h3 style={{"margin": "0 0 1rem 0", "fontSize": "1.1rem", "color": "rgba(255,255,255,0.9)"}}>
                                                    AI Analysis
                                                </h3>
                                                <div style={{"display": "grid", "gap": "0.75rem"}}>
                                                    <div className="stat-item">
                                                        <span className="stat-label">Best Deal:</span>
                                                        <span className="stat-value" style={{"color": "#4ade80"}}>
                                                            {comparison.best_store}
                                                        </span>
                                                    </div>
                                                    <div className="stat-item">
                                                        <span className="stat-label">Worst Deal:</span>
                                                        <span className="stat-value" style={{"color": "#f87171"}}>
                                                            {comparison.worst_store}
                                                        </span>
                                                    </div>
                                                    <div className="stat-item">
                                                        <span className="stat-label">Average Price:</span>
                                                        <span className="stat-value">
                                                            ${comparison.avg_price.toFixed(2)}
                                                        </span>
                                                    </div>
                                                    <div style={{"marginTop": "0.5rem", "padding": "1rem", "background": "rgba(255,255,255,0.05)", "borderRadius": "8px", "borderLeft": "3px solid #3b82f6"}}>
                                                        <div style={{"fontSize": "0.85rem", "color": "rgba(255,255,255,0.6)", "marginBottom": "0.5rem"}}>
                                                            Recommendation
                                                        </div>
                                                        <div style={{"color": "rgba(255,255,255,0.9)", "lineHeight": "1.5"}}>
                                                            {comparison.recommendation}
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    ) if comparison else None}
                                    <div className="card">
                                        {(
                                            <div className="loading-message">Loading stores...</div>
                                        ) if storesLoading else (
                                            <div>
                                                {(
                                                    <div className="empty-message">
                                                        No stores added yet. Add prices above!
                                                    </div>
                                                ) if stores.length == 0 else (
                                                    <div>
                                                        {(bestPrice) and (
                                                            <div className="best-price-banner">
                                                                <div style={{"display": "flex", "alignItems": "center", "gap": "0.5rem"}}>
                                                                    <span style={{"fontSize": "1.5rem"}}>🏆</span>
                                                                    <div>
                                                                        <div style={{"fontWeight": "600", "color": "rgba(255,255,255,0.9)"}}>
                                                                            Best Price: {bestPrice.name}
                                                                        </div>
                                                                        <div style={{"fontSize": "0.85rem", "color": "rgba(255,255,255,0.6)"}}>
                                                                            ${bestPrice.price.toFixed(2)}
                                                                        </div>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        )}
                                                        <div style={{"marginTop": "1rem"}}>
                                                            {[
                                                                <StoreItem
                                                                    key={store.name}
                                                                    store={store}
                                                                    onDelete={deleteStore}
                                                                    isBest={bestPrice and store.name == bestPrice.name}
                                                                /> for store in stores
                                                            ]}
                                                        </div>
                                                    </div>
                                                )}
                                            </div>
                                        )}
                                    </div>
                                </div>
                            )}
                        </div>

                    </div>
                </div>
            </div>;
    }

    return
        <AuthForm
            isSignup={isSignup}
            username={username}
            password={password}
            error={error}
            loading={loading}
            onUsernameChange={lambda e: any -> None { username = e.target.value; }}
            onPasswordChange={lambda e: any -> None { password = e.target.value; }}
            onSubmit={handleSubmit}
            onToggleMode={lambda -> None { isSignup = not isSignup; error = ""; }}
        />;
}

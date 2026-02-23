"""Implementations for the Price Comparator frontend component."""

impl app.fetchProducts -> None {
    productsLoading = True;
    result = root spawn ListProducts();
    products = result.reports[0] if result.reports else [];
    productsLoading = False;
}

impl app.addProduct -> None {
    if not newProductName.trim() { return; }
    response = root spawn AddProduct(title=newProductName);
    newProduct = response.reports[0];
    products = products.concat([{"id": newProduct.id, "name": newProduct.name, "category": newProduct.category}]);
    newProductName = "";
}

impl app.deleteProduct(productId: str) -> None {
    root spawn DeleteProduct(product_id=productId);
    products = products.filter(lambda p: any -> bool { return p.id != productId; });
    if selectedProductId == productId {
        selectedProductId = "";
        selectedProductName = "";
        stores = [];
        comparison = None;
    }
}

impl app.selectProduct(productId: str, productName: str) -> None {
    selectedProductId = productId;
    selectedProductName = productName;
    comparison = None;
    await fetchStores(productId);
}

impl app.fetchStores(productId: str) -> None {
    storesLoading = True;
    result = root spawn ListStorePrices(product_id=productId);
    stores = result.reports[0] if result.reports else [];
    storesLoading = False;
}

impl app.addStore -> None {
    if not newStoreName.trim() or not newStorePrice { return; }
    priceValue = parseFloat(newStorePrice);
    if isNaN(priceValue) or priceValue < 0 { return; }
    currentDate = Date().toISOString();
    response = root spawn AddStorePrice(
        product_id=selectedProductId,
        store_name=newStoreName,
        price=priceValue,
        url=newStoreUrl,
        last_updated=currentDate
    );
    if response.reports and response.reports.length > 0 {
        stores = stores.concat([{"name": newStoreName, "price": priceValue, "available": True, "url": newStoreUrl, "last_updated": currentDate}]);
        newStoreName = "";
        newStorePrice = "";
        newStoreUrl = "";
        comparison = None;
    }
}

impl app.deleteStore(storeName: str) -> None {
    root spawn DeleteStore(product_id=selectedProductId, store_name=storeName);
    stores = stores.filter(lambda s: any -> bool { return s.name != storeName; });
    comparison = None;
}

impl app.compareAllPrices -> None {
    if stores.length < 2 { return; }
    comparisonLoading = True;
    result = root spawn ComparePrices(product_id=selectedProductId, product_name=selectedProductName);
    if result.reports and result.reports.length > 0 {
        compData = result.reports[0];
        if not compData.error { comparison = compData; }
    }
    comparisonLoading = False;
}

impl app.handleLogin -> None {
    error = "";
    if not username.trim() or not password { error = "Please fill in all fields"; return; }
    loading = True;
    success = await jacLogin(username, password);
    loading = False;
    if success { isLoggedIn = True; username = ""; password = ""; }
    else { error = "Invalid username or password"; }
}

impl app.handleSignup -> None {
    error = "";
    if not username.trim() or not password { error = "Please fill in all fields"; return; }
    if password.length < 4 { error = "Password must be at least 4 characters"; return; }
    loading = True;
    result = await jacSignup(username, password);
    loading = False;
    if result["success"] { isLoggedIn = True; username = ""; password = ""; }
    else { error = result["error"] if result["error"] else "Signup failed"; }
}

impl app.handleLogout -> None {
    jacLogout();
    isLoggedIn = False;
    products = [];
    stores = [];
    selectedProductId = "";
    selectedProductName = "";
    comparison = None;
    currentPage = "home";
    selectedStoreEntry = None;
    nearbyStores = [];
}

impl app.handleSubmit(e: any) -> None {
    e.preventDefault();
    if isSignup { await handleSignup(); } else { await handleLogin(); }
}

impl app.handleProductKeyPress(e: any) -> None {
    if e.key == "Enter" { addProduct(); }
}

impl app.handleStoreKeyPress(e: any) -> None {
    if e.key == "Enter" { addStore(); }
}

impl app.getBestPrice -> any {
    if stores.length == 0 { return None; }
    availableStores = stores.filter(lambda s: any -> bool { return s.available; });
    if availableStores.length == 0 { return None; }
    best = availableStores[0];
    for store in availableStores { if store.price < best.price { best = store; } }
    return best;
}

impl app.fetchStoreEntries -> None {
    storeEntriesLoading = True;
    result = root spawn ListStoreEntries();
    storeEntries = result.reports[0] if result.reports else [];
    storeEntriesLoading = False;
}

impl app.addStoreEntry -> None {
    if not newStoreEntryName.trim() { return; }
    response = root spawn AddStoreEntry(name=newStoreEntryName);
    if response.reports and response.reports.length > 0 {
        newEntry = response.reports[0];
        storeEntries = storeEntries.concat([{"id": newEntry.id, "name": newEntry.name}]);
        newStoreEntryName = "";
    }
}

impl app.deleteStoreEntry(storeId: str) -> None {
    root spawn DeleteStoreEntry(store_id=storeId);
    storeEntries = storeEntries.filter(lambda s: any -> bool { return s.id != storeId; });
}

impl app.handleStoreEntryKeyPress(e: any) -> None {
    if e.key == "Enter" { addStoreEntry(); }
}

# --- Routing ---

impl app.navigateToStoreProducts(store: any) -> None {
    selectedStoreEntry = store;
    currentPage = "store-products";
}

impl app.navigateHome -> None {
    currentPage = "home";
    selectedStoreEntry = None;
}

# --- Location search (LLM-powered) ---

impl app.getUserLocation -> None {
    locationError = "";
    if not navigator.geolocation {
        locationError = "Geolocation is not supported by your browser.";
        return;
    }
    locationLoading = True;
    navigator.geolocation.getCurrentPosition(
        lambda position: any -> None {
            lat = position.coords.latitude.toFixed(4);
            lng = position.coords.longitude.toFixed(4);
            locationQuery = lat + ", " + lng;
            locationLoading = False;
            searchNearbyStores();
        },
        lambda err: any -> None {
            locationError = "Could not get your location. Please type it instead.";
            locationLoading = False;
        }
    );
}

impl app.searchNearbyStores -> None {
    locationError = "";
    nearbyStores = [];

    if not locationQuery.trim() {
        locationError = "Please enter a location.";
        return;
    }

    locationLoading = True;
    result = root spawn FindNearbyStores(location=locationQuery);

    if result.reports and result.reports.length > 0 {
        storeList = result.reports[0];
        if storeList and storeList.length > 0 {
            # Manual bubble sort by distance ascending
            n = storeList.length;
            i = 0;
            while i < n {
                j = 0;
                while j < n - i - 1 {
                    if storeList[j].distance > storeList[j + 1].distance {
                        temp = storeList[j];
                        storeList[j] = storeList[j + 1];
                        storeList[j + 1] = temp;
                    }
                    j = j + 1;
                }
                i = i + 1;
            }
            nearbyStores = storeList;
        } else {
            locationError = "No stores found near that location. Try a different city or address.";
        }
    } else {
        locationError = "No results returned. Try a more specific location.";
    }

    locationLoading = False;
}

impl app.handleLocationKeyPress(e: any) -> None {
    if e.key == "Enter" { searchNearbyStores(); }
}
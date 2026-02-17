"""StoreEntryItem — a single row in the global store list."""

def:pub StoreEntryItem(
    store: dict,
    onDelete: any
) -> obj {
    return
        <div className="ingredient-item">
            <div className="ingredient-info">
                <span className="ingredient-name">{store.name}</span>
            </div>
            <div className="ingredient-meta">
                <button
                    onClick={lambda -> None { onDelete(store.id); }}
                    className="btn-delete"
                    style={{"marginLeft": "0.5rem"}}
                >
                    ×
                </button>
            </div>
        </div>;
}

"""Product item component for the products list."""

def:pub ProductItem(
    product: dict,
    isSelected: bool,
    onSelect: any,
    onDelete: any
) -> obj {
    return
        <div 
            className={("product-item" + (" product-selected" if isSelected else ""))}
            onClick={lambda -> None { onSelect(product.id); }}
            style={{"cursor": "pointer"}}
        >
            <div className="ingredient-info">
                <span className="ingredient-name">{product.name}</span>
                <span className="category-badge" style={{
                    "fontSize": "0.75rem",
                    "padding": "0.25rem 0.5rem",
                    "borderRadius": "4px",
                    "background": "rgba(59, 130, 246, 0.2)",
                    "color": "#60a5fa"
                }}>
                    {product.category}
                </span>
            </div>
            <div className="ingredient-meta">
                <button
                    onClick={lambda e: any -> None {
                        e.stopPropagation();
                        onDelete(product.id);
                    }}
                    className="btn-delete"
                    style={{"marginLeft": "0.5rem"}}
                >
                    ×
                </button>
            </div>
        </div>;
}

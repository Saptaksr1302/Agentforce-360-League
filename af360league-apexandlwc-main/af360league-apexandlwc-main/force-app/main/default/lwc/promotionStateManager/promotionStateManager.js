import { defineState } from '@lwc/state';

const promotionStateManager = defineState(({atom, setAtom, computed}) => {

    const promotionName = atom('');
    const chosenProducts = atom([]);
    const chosenStores = atom([]);

    const setProduct = (product) => {
        let chosenProductsTemp = [...chosenProducts.value];

        const existingIndex = chosenProductsTemp.findIndex(
            p => p.productId === product.productId
        );

        if (existingIndex >= 0) {
            chosenProductsTemp[existingIndex] = {
                ...chosenProductsTemp[existingIndex],
                ...product
            };
        } else {
            chosenProductsTemp.push(product);
        }

        setAtom(chosenProducts, chosenProductsTemp);
    };

    const removeProduct = (productId) => {
        let chosenProductsTemp =
            chosenProducts.value.filter(p => p.productId !== productId);
        setAtom(chosenProducts, chosenProductsTemp);
    };

    const updateProducts = (products) => {
        setAtom(chosenProducts, [...products]);
    };

    const isProductSelected = (productId) => {
        return chosenProducts.value.some(p => p.productId === productId);
    };

    const getProductDiscount = (productId) => {
        const product = chosenProducts.value.find(
            p => p.productId === productId
        );
        return product ? product.discountPercent : 0;
    };

    const productCount = computed([chosenProducts], (products) => products.length);

    const updateStores = (stores) => {
        setAtom(chosenStores, [...stores]);
    };

    const updatePromotionName = (name) => {
        setAtom(promotionName, name);
    };

    return {
        promotionName,
        chosenProducts,
        setProduct,
        removeProduct,
        updateProducts,
        isProductSelected,
        getProductDiscount,
        productCount,
        chosenStores,
        updateStores,
        updatePromotionName
    };
});

export default promotionStateManager;

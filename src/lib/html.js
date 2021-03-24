export function append2body (elem) {
    document.body.appendChild(elem);
}

export function remove (elem) {
    elem.parentNode.removeChild(elem);
}

export function html (selector, attributes = null, children = null) {
    const tag = selector.split(/#|\./)[0];
    
    const classes = selector.match(/\.[\w-]+/g)?.map(s => s.replace('.',''));
    const id = selector.match(/#[\w-]+/g);

    if ((classes || id) && (!attributes || attributes?.length == 0)) attributes = []

    if (classes) attributes.classes = classes;
    if (id) attributes.id = id[0].replace('#', '');

    const elem = document.createElement(tag);

    if (attributes) addAttributes(elem, attributes); 
    if (children) addChildren(elem, children);

    return elem;
}

function addAttributes (elem, attributes) {
    Object.keys(attributes).forEach(key => {
        switch (key) {
            case 'classes':
                attributes[key].forEach(cls => elem.classList.add(cls));
                break;
            case 'textContent':
                elem.textContent = attributes[key];
                break;
            case 'selected':
                elem.selected = attributes[key];
            default:
                elem.setAttribute(key, attributes[key]);
        }
    });
}

function addChildren (elem, children) {
    children.forEach(child => {
        if (typeof child == 'string') {
            if (child.startsWith('<')) {
                const stringElem = child;
                const template = document.createElement('template');
                template.innerHTML = stringElem;
                child = template.content;
            } else {
                child = document.createTextNode(child);
            }
        } 
        elem.appendChild(child);
    });
}

import { html as h, append2body, remove } from './html.js';

export function savePng (canvas) {
    const data = canvas.toDataURL('image/png');
    const a = h('a', {download: 'img.png', href: data, style: 'display:none'});

    append2body(a);
    a.click();
    remove(a);
}
%{
  title: "Using JavaScript packages in Phoenix LiveViews",
  author: "Samuel Willis",
  tags: ~w(projects elixir phoenix JavaScript leaflet),
  description: "How to integrate Leafletjs - or any NPM package - into Phoenix LiveView",
  published: true
}
---
Documentation for adding [Leafletjs](https://leafletjs.com/) - or any other NPM package - to [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/welcome.html) is somewhat limited.
Frankly, it was more challenging to figure out than I'd like to admit.
So I thought a quick _How To_ article could help others looking to integrate an
NPM dependency and its accompanying CSS into their projects.

This guide assumes you have a Phoenix App set up. If not, [start here](https://hexdocs.pm/phoenix/up_and_running.html).

# TL;DR

If you're just here for the good stuff, here are the ey steps to add a NPM
package and its CSS:

1. Install package in `assets/` directory:
    * `npm install --prefix assets/ $PACKAGE_NAME --save`
2. Import JS into `app.js` and use:
    * `import $PACKAGE from '$PACKAGE_NAME';`
3. Import CSS into `app.css` and use:
    * `@import '$PACKAGE_NAME/path/to/css/file.css';`

The above will get the styles and JS working for the most part.
If the depenedency has static assets, like images, that it uses in its styles
those assets will need to be copied to the appropriate path in `priv/static/`.
You may also need to configure a custom `Plug.Static`

If you'd like to know more and see an example, feel free to continue reading.

## Importing a NPM package
Phoenix's [asset management
documentation](https://hexdocs.pm/phoenix/asset_management.html) is your
starting point.

There are two methods to import an NPM package. First, you can vendor it in your project, importing it in `app.js`. The second method, which this article focuses on, involves installing the package via NPM in the `assets/` directory, letting `esbuild` handle it. This approach is preferable for its smaller build size, ease of updates, and automatic dependency resolution.

To do this, go to the `assets/` directory and run:

```bash
npm install leaflet --save
```

With the package installed, esbuild will bundle it when we use it.

## Using the package's JavaScript
To use the package, import it into `app.js`.
Here's an example [Client
Hook](https://hexdocs.pm/phoenix_live_view/js-interop.html#client-hooks-via-phx-hook)
that sets up a basic Leafletjs map:

```javascript
// assets/Map.js
import L from 'leaflet';

const Map = {
  mounted() {
    const map = L.map("map").setView([41, 69], 2);
    L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}', {
      attribution: 'Tiles &copy; Esri &mdash; Esri, DeLorme, NAVTEQ, TomTom, Intermap, iPC, USGS, FAO, NPS, NRCAN, GeoBase, Kadaster NL, Ordnance Survey, Esri Japan, METI, Esri China (Hong Kong), and the GIS User Community',
      nowrap: true,
    }).addTo(map);

    this.map = map;
  },
};

export default Map;
```

Then, import this hook into `app.js`:

```javascript
// assets/js/app.js
import Map from './Map';

const Hooks = {
  Map,
}

let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: Hooks});
```

Use this hook in a LiveView's markup:

```html
<div id="map" class="w-full h-[500px] p-20" phx-hook="Map"></div>
```

However, initially, the map might not have the desired styling.

## Importing a packages styles

The trickiest part for me was importing the package's styles.
The [Phoenix
documentation](https://hexdocs.pm/phoenix/asset_management.html#css) on this
topic was not very clear.

Despite what the documentation suggests, by default, esbuild does not handle CSS
because tailwind typically manages CSS building.

However, if the JavaScript package uses simple CSS, it can be imported in
`app.css`, and tailwind will process it.
For LeafletJS, this looks like:

```css
# assets/css/app.css
@import 'leaflet/dist/leaflet.css';
```

With this import, the styles are applied correctly.

## Fixing relative path references to assets in dependency styles

In Leaflet's case, there are image assets referenced via a relative path in the
CSS.
Esbuild bundles assets to `priv/static/assets`, so each image request is
prefixed by `assets/`, which leads to a `404` error.

To solve this, there are two steps:

First, it is necessary to copy the assets to the appropriate directories in
`priv/static`.
This enables static serving of the assets.

Second, it is essential to configure the assets to be accessible with the
`assets/` prefix, as Phoenix's default behavior is to serve static assets from the
root.

To maintain the default behavior and prevent breaking any existing references to
assets, a second [Plug.Static](https://hexdocs.pm/plug/Plug.Static.html) can be
configured.

By adding the following to `endpoint.ex`, the images in `priv/static/images` become
accessible at paths beginning with `assets/images`:

```elixir
# lib/your_app_web/endpoint.ex
plug Plug.Static,
  at: "/assets",
  from: {:your_app, "priv/static"},
  gzip: false,
  only: ~w(images)
```
For clarification, here's a breakdown of the above settings:

* **at: "/assets":** This serves the files at the URL path `/assets/.*`
* **from: {:your_app, "priv/static"}:** This tells Phoenix to serve files from the
  `priv/static` directory in your app.
* **only: ~w(images):** This restricts the serving to only the `images/` directory
  within `priv/static`

As a result, images stored in `priv/static` are available at both `images/*` and
`/assets/images/*`

## Conclusion

Integrating NPM packages into Phoenix LiveView is straightforward once
understood.
Part of the challenge was navigating the sparse docs that are split between
the Phoenix hexdocs and the Phoenix LiveView hexdocs.

With this guide, getting a JavaScript dependency imported along with its styles
should be straighforward.

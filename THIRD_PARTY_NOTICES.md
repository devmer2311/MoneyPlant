# Third-party assets and feature dependencies

Fonts are bundled from https://github.com/google/fonts under their respective OFL licenses in assets/fonts/*-OFL.txt. Variable font sources were instantiated to static 400/700 weights for offline PDF compatibility. DM Serif Display has only an upstream regular upright face; both registrations use that face.

barcode_widget: Apache-2.0. file_picker, csv, excel: MIT. local_auth: BSD-3-Clause. Complete notices are included in Flutter's Open-source licenses screen.

PDF statement extraction uses syncfusion_flutter_pdf 33.2.13, under Syncfusion's Community or commercial license. The owner approved this dependency. Distribution/use must comply with https://www.syncfusion.com/products/communitylicense and the package LICENSE. The compatible version is pinned because newer releases require xml 7, while excel 4 requires xml <7. file_picker 11 is used because the current package_info_plus requires win32 5.

App updates: http, pub_semver and url_launcher use BSD-3-Clause licenses; workmanager uses MIT. Their package licenses are included in Flutter’s license registry.

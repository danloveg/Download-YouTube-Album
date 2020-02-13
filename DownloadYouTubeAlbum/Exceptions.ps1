Class DependencyException : System.Exception {
    DependencyException([String] $Message) : base($Message) {}
}

Class AlbumManifestException : System.Exception {
    AlbumManifestException([String] $Message) : base($Message) {}
}
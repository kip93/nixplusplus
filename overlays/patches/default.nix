{ nixpkgs, self, ... } @ inputs:
final: prev: with final; {
  jre_headless = prev.jre_headless.overrideAttrs (prev': {
    nativeBuildInputs = (prev'.nativeBuildInputs or [ ]) ++
      (with buildPackages; [ autoconf stdenv.cc which zip ])
    ;
    configureFlags = (prev'.configureFlags or [ ]) ++
      (lib.optionals (buildPlatform != hostPlatform) [
        "--with-boot-jdk=${buildPackages.jre_headless.home}"
        "--with-build-jdk=${buildPackages.jre_headless.home}"
      ])
    ;
  });
  languagetool = prev.languagetool.override {
    jre = jre_headless;
  };
}

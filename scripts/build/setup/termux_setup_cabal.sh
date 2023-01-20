# shellcheck shell=bash
termux_setup_cabal() {
	if [[ "${TERMUX_ON_DEVICE_BUILD}" == false ]]; then
		local TERMUX_CABAL_VERSION=3.6.2.0
		local TERMUX_CABAL_TAR="${TERMUX_COMMON_CACHEDIR}/cabal-${TERMUX_CABAL_VERSION}.tar.xz"

		local TERMUX_CABAL_RUNTIME_FOLDER

		if [[ "${TERMUX_PACKAGES_OFFLINE-false}" == true ]]; then
			TERMUX_CABAL_RUNTIME_FOLDER="${TERMUX_SCRIPTDIR}/build-tools/cabal-${TERMUX_CABAL_VERSION}-runtime"
		else
			TERMUX_CABAL_RUNTIME_FOLDER="${TERMUX_COMMON_CACHEDIR}/cabal-${TERMUX_CABAL_VERSION}-runtime"
		fi

		export PATH="${TERMUX_CABAL_RUNTIME_FOLDER}:${PATH}"

		[[ -d "${TERMUX_CABAL_RUNTIME_FOLDER}" ]] && return

		termux_download "https://github.com/MrAdityaAlok/ghc-cross-tools/releases/download/cabal-install-v${TERMUX_CABAL_VERSION}/cabal-install-${TERMUX_CABAL_VERSION}.tar.xz" \
			"${TERMUX_CABAL_TAR}" \
			"f433e99cb3ff85239bd633f2ae2a370bfb7103f9db80e38199e0fda27897bdfe"

		mkdir -p "${TERMUX_CABAL_RUNTIME_FOLDER}"
		tar xf "${TERMUX_CABAL_TAR}" -C "${TERMUX_CABAL_RUNTIME_FOLDER}"
		rm "${TERMUX_CABAL_TAR}"

		export CABAL_CONFIG="$TERMUX_CABAL_RUNTIME_FOLDER/config"
		# Configure cabal for Termux:
		cabal update
		local _ghc_host="$TERMUX_HOST_PLATFORM"
		if [[ "$TERMUX_ARCH" == "arm" ]]; then _ghc_host="armv7a-linux-androideabi"; fi
		cabal user-config update \
			-a "tests: False" \
			-a "extra-include-dirs: $TERMUX_PREFIX/include" \
			-a "extra-lib-dirs: $TERMUX_PREFIX/lib" \
			-a "configure-option: --host=$_ghc_host" \
			-a "executable-static: True" \
			-a "install-method: copy" \
			-a "installdir: $TERMUX_PREFIX/bin"
		# Workaround for https://github.com/haskell/cabal/issues/6823
		sed -i \
			-e "s|-- \(prefix:\).*|\1 $TERMUX_PREFIX|g" \
			-e "s|-- \(hsc2hs-options:\)|\1 --cross-compile|" \
			-e "s|-- \(ghc-options:\)|\1 -optl-Wl,--enable-new-dtags -optl-Wl,-rpath=$TERMUX_PREFIX/lib|" \
			"$CABAL_CONFIG"
	else
		if [[ "${TERMUX_APP_PACKAGE_MANAGER}" == "apt" ]] && "$(dpkg-query -W -f '${db:Status-Status}\n' cabal-install 2>/dev/null)" != "installed" ||
			[[ "${TERMUX_APP_PACKAGE_MANAGER}" == "pacman" ]] && ! "$(pacman -Q cabal-install 2>/dev/null)"; then
			echo "Package 'cabal-install' is not installed."
			exit 1
		fi
	fi
}

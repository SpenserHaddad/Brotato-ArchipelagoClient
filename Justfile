set dotenv-load
export PYTHONPATH := env('AP_DIR')
# Redeclare envirnment variables to make it more obvious which are needed
export AP_DIR := env('AP_DIR')
export BROTATO_PACKED_DIR := env('BROTATO_PACKED_DIR')
export BROTATO_UNPACKED_DIR := env('BROTATO_UNPACKED_DIR')

# Constants
export APWORLD := 'brotato'
export GDRETOOLS_VERSION := "v2.4.0"
export TOOLS_DIR := "tools"
export LOCAL_TOOLS_DIR := ".local_tools"
export GDRETOOLS_DIR := ".local_tools/gdre_tools" # TODO: Have this use LOCAL_TOOLS_DIR?
export GODOT_STEAM_TAG := "v3.29"
export GODOT_STEAM_DIR := ".local_tools/godot_steam"


# Setup recipes
install_ap_deps:
    uv run python -m ensurepip
    uv run python ${AP_DIR}/ModuleUpdate.py --yes --append ${AP_DIR}/WebHostLib/requirements.txt

create_symlinks:
    uv run python ${TOOLS_DIR}/create_dev_symlinks.py -a ${AP_DIR} -b ${BROTATO_UNPACKED_DIR}
    # ln -sf $(realpath apworld/${APWORLD}/) ${AP_DIR}/worlds/${APWORLD}
download_gdretools:
    uv run tools/download_gdretools.py ${GDRETOOLS_VERSION} -o ${GDRETOOLS_DIR}

download_godot:
    uv run tools/download_godot.py ${GODOT_STEAM_TAG} -o ${GODOT_STEAM_DIR}

extract_brotato: download_gdretools
    uv run tools/extract_brotato.py ${BROTATO_PACKED_DIR} ${BROTATO_UNPACKED_DIR} -g ${GDRETOOLS_DIR}

dev_setup: download_godot download_gdretools extract_brotato create_symlinks install_ap_deps

# Code check/development recipes

@test:
    ${AP_DIR}/.env/bin/pytest ${AP_DIR}/worlds/${APWORLD}

format:
    uv run ruff format
    uv run ruff check --select I --fix

lint *FLAGS:
    uv run ruff check {{ FLAGS }}

types:
    ty check ${APWORLD}

apworld:
    zip -r ${APWORLD}.apworld apworld/${APWORLD}/ -x "**__pycache__/*" -x "apworld/${APWORLD}/test/*"



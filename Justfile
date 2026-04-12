set dotenv-load
export PYTHONPATH := env('AP_DIR')
# Just to make it more obvious that this is a needed envvar
export AP_DIR := env('AP_DIR')
export BROTATO_DIR := env('BROTATO_DIR')
export APWORLD := 'brotato'
export GDRETOOLS_VERSION := "v2.4.0"
export TOOLS_DIR := "tools"
export LOCAL_TOOLS_DIR := ".local_tools"

ap_dir:
    echo ${AP_DIR}

install_ap_deps:
    uv run python ${AP_DIR}/ModuleUpdate.py --yes --append ${AP_DIR}/WebHostLib/requirements.txt

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

create_symlinks:
    uv run python ${TOOLS_DIR}/create_dev_symlinks.py -a ${AP_DIR} -b ${BROTATO_DIR}
    # ln -sf $(realpath apworld/${APWORLD}/) ${AP_DIR}/worlds/${APWORLD}

apworld_dir:
    ls ${APWORLD}

download_gdretools:
    uv run tools/download_gdsdecomp.py ${GDRETOOLS_VERSION} -o ${LOCAL_TOOLS_DIR}/gdre_tools

# extract_brotato:
#     {{ if ! path_exists("${GDRETOOLS_DIR}") { just download_gdsdecomp } }}
#     uv run tools/extract_brotato.py ${BROTATO_DIR} ../BrotatoUnpacked -g ${GDRETOOLS_DIR}
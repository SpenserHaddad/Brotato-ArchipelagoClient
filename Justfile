set dotenv-load
export PYTHONPATH := env('AP_DIR')
export BROTATO_DIR := env('BROTATO_DIR')
export APWORLD := 'brotato'
export GDRETOOLS_VERSION := "v2.4.0"
export GDRETOOLS_DIR := ".tools/gdre_tools"

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

symlink_to_ap:
    ln -sf $(realpath apworld/${APWORLD}/) ${AP_DIR}/worlds/${APWORLD}

apworld_dir:
    ls ${APWORLD}

download_gdsdecomp:
    uv run tools/download_gdsdecomp.py ${GDRETOOLS_VERSION} -o ${GDRETOOLS_DIR}

# extract_brotato:
#     {{ if ! path_exists("${GDRETOOLS_DIR}") { just download_gdsdecomp } }}
#     uv run tools/extract_brotato.py ${BROTATO_DIR} ../BrotatoUnpacked -g ${GDRETOOLS_DIR}
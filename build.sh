#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

TAG="${1}"
REPO_ROOT="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
PROJ_NAME="equinox"

if [ -z "$TAG" ]; then
    echo "Error: arg must be set to TAG of ${PROJ_NAME} you want to build docs for" >&2
    exit 1
fi

# Install uv only if it's not already installed
if ! command -v uv &> /dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    source $HOME/.cargo/env
fi

REPO_DIR=$(mktemp -d)
git clone --depth 1 --branch "${TAG}" https://github.com/patrick-kidger/equinox "${REPO_DIR}"

cd "${REPO_DIR}"
# python version to match https://github.com/patrick-kidger/equinox/blob/main/.github/workflows/build_docs.yml
uv venv --python=3.11
source .venv/bin/activate
uv pip install .
uv pip install mkdocs-autorefs==1.1.0 # latest version incompatible with mkdocs specified in requirements.txt
uv pip install -r docs/requirements.txt
mkdocs build
# yes twice: https://github.com/patrick-kidger/equinox/blob/5a40d2ed61871b400674ff3b3c6e8f5ba410d899/.github/workflows/build_docs.yml#L33
mkdocs build
HTML_DIR="${PWD}/site"
deactivate

cd "${REPO_ROOT}"
uv venv
source .venv/bin/activate
uv pip install -r requirements.txt
python fixup.py "${HTML_DIR}"
doc2dash -f -d ./ \
  --online-redirect-url https://docs.kidger.site/equinox/ \
  --name "${PROJ_NAME}" \
  --icon "${REPO_DIR}/docs/_static/favicon.png" \
  --index-page "${HTML_DIR}/index.html" \
  "${HTML_DIR}"
tar --exclude='.DS_Store' -cvzf "${TAG}.tgz" ${PROJ_NAME}.docset

echo "Wrote ${PROJ_NAME}.docset and ${TAG}.tgz"

# readonly xml_file="${PROJ_NAME}.xml"

# if [ ! -f "${xml_file}" ]; then
#     echo "Error: File ${xml_file} not found."
#     exit 1
# fi

# python update_xml.py --tag="${TAG}" --proj_name="${PROJ_NAME}"


# git add "${xml_file}"
# git config --global user.email "garymm@garymm.org"
# git config --global user.name "Gary Mindlin Miguel"
# git commit -m "Update version to ${TAG}"
# git tag -a "${TAG}" -m "${PROJ_NAME} ${TAG}"
# git push origin "${TAG}"
# git push origin

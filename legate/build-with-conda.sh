cd legate.core.internal
./scripts/generate-conda-envs.py --ctk 12.4.0 --os linux --openmpi --ucx --compilers 
conda env create -f ./environment-test-linux-cuda12.4.0-compilers-openmpi-ucx.yaml --name legate
conda activate legate
./configure --with-clean --with-python --with-openmp --with-cuda  --build-type
debug;
export LEGATE_ARCH='arch-linux-py-cuda-debug'
export LEGATE_DIR='/home/idemeshko/development/legate.core.internal'
make -j; pip install .
cd cunumeric.internal
 ./install.py --verbose --no-clean  --editable  -j 16 --with-tests --debug

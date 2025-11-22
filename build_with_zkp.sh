#!/bin/bash
# Build script for DroneAuth with ZKP integration

echo "========================================"
echo "Building DroneAuth with ZKP Support"
echo "========================================"
echo ""

# Set colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "omnetpp.ini" ]; then
    echo -e "${RED}Error: omnetpp.ini not found. Please run from DroneAuth directory${NC}"
    exit 1
fi

# Step 1: Copy ZKP files
echo -e "${YELLOW}Step 1: Copying ZKP module files...${NC}"
if [ -f "zkp_test/ZKPModule.h" ] && [ -f "zkp_test/ZKPModule.cc" ]; then
    cp zkp_test/ZKPModule.h src/
    cp zkp_test/ZKPModule.cc src/
    echo -e "${GREEN}✓ ZKP files copied${NC}"
else
    echo -e "${RED}✗ ZKP files not found in zkp_test/${NC}"
    exit 1
fi

# Step 2: Verify updated source files exist
echo -e "\n${YELLOW}Step 2: Verifying source files...${NC}"
FILES=(
    "src/ZKPModule.h"
    "src/ZKPModule.cc"
    "src/DroneAuthApp.h"
    "src/DroneAuthApp.cc"
    "src/GroundStation.h"
    "src/GroundStation.cc"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file"
    else
        echo -e "${RED}✗${NC} $file ${RED}NOT FOUND${NC}"
        echo -e "${YELLOW}Please save the updated file from the artifacts${NC}"
        exit 1
    fi
done

# Step 3: Clean old build
echo -e "\n${YELLOW}Step 3: Cleaning old build...${NC}"
rm -rf out/
mkdir -p out/gcc-release/src
echo -e "${GREEN}✓ Clean complete${NC}"

# Step 4: Set environment (if needed)
echo -e "\n${YELLOW}Step 4: Setting up environment...${NC}"
if [ -z "$OMNETPP_ROOT" ]; then
    echo -e "${YELLOW}Warning: OMNETPP_ROOT not set${NC}"
    echo -e "${YELLOW}Attempting to detect...${NC}"
    # Try to find OMNeT++ root
    if [ -d "/opt/omnetpp" ]; then
        export OMNETPP_ROOT="/opt/omnetpp"
    elif [ -d "$HOME/omnetpp" ]; then
        export OMNETPP_ROOT="$HOME/omnetpp"
    fi
fi

if [ -z "$INET_ROOT" ]; then
    echo -e "${YELLOW}Warning: INET_ROOT not set${NC}"
fi

# Step 5: Compile ZKP Module
echo -e "\n${YELLOW}Step 5: Compiling ZKP Module...${NC}"
g++ -c -std=c++17 -O2 -DINET_IMPORT \
    -I. -Isrc \
    -I$OMNETPP_ROOT/include \
    -I$INET_ROOT/src \
    -o out/gcc-release/src/ZKPModule.o \
    src/ZKPModule.cc

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ ZKPModule compiled${NC}"
else
    echo -e "${RED}✗ ZKPModule compilation failed${NC}"
    exit 1
fi

# Step 6: Compile DroneAuthApp
echo -e "\n${YELLOW}Step 6: Compiling DroneAuthApp...${NC}"
g++ -c -std=c++17 -O2 -DINET_IMPORT -DWITH_UDP \
    -I. -Isrc \
    -I$OMNETPP_ROOT/include \
    -I$INET_ROOT/src \
    -o out/gcc-release/src/DroneAuthApp.o \
    src/DroneAuthApp.cc

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ DroneAuthApp compiled${NC}"
else
    echo -e "${RED}✗ DroneAuthApp compilation failed${NC}"
    exit 1
fi

# Step 7: Compile GroundStation
echo -e "\n${YELLOW}Step 7: Compiling GroundStation...${NC}"
g++ -c -std=c++17 -O2 -DINET_IMPORT -DWITH_UDP \
    -I. -Isrc \
    -I$OMNETPP_ROOT/include \
    -I$INET_ROOT/src \
    -o out/gcc-release/src/GroundStation.o \
    src/GroundStation.cc

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ GroundStation compiled${NC}"
else
    echo -e "${RED}✗ GroundStation compilation failed${NC}"
    exit 1
fi

# Step 8: Link executable
echo -e "\n${YELLOW}Step 8: Linking executable...${NC}"
g++ -shared -o out/gcc-release/src/libDroneAuth.so \
    out/gcc-release/src/ZKPModule.o \
    out/gcc-release/src/DroneAuthApp.o \
    out/gcc-release/src/GroundStation.o \
    -L$INET_ROOT/src -lINET \
    -lssl -lcrypto \
    -Wl,-rpath,$INET_ROOT/src

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Linking successful${NC}"
else
    echo -e "${RED}✗ Linking failed${NC}"
    exit 1
fi

echo ""
echo "========================================"
echo -e "${GREEN}BUILD SUCCESSFUL!${NC}"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Run simulation: opp_run -l out/gcc-release/src/libDroneAuth.so -n src:.:$INET_ROOT/src -u Cmdenv"
echo "2. Or use OMNeT++ IDE"
echo ""

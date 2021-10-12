UPCC=upcc
CC=clang
THREADS=2
BUILD_DIR=build

LAPLACE_UPC=ex3 ex4 ex5 ex6 optimized
LAPLACE_UPC_OUT=$(LAPLACE_UPC:%=$(BUILD_DIR)/laplace_%)
HEAT_UPC=heat_1 heat_3 heat_4
HEAT_UPC_OUT=$(HEAT_UPC:%=$(BUILD_DIR)/%)

build: $(BUILD_DIR)/laplace_ex2 $(BUILD_DIR)/heat_c $(LAPLACE_UPC_OUT) $(HEAT_UPC_OUT)
.PHONY: build

$(BUILD_DIR)/laplace_ex2: laplace/ex2.c laplace/settings.h
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/heat_c: 2d_heat/heat_c.c 2d_heat/settings.h
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $< -o $@ -lm

$(LAPLACE_UPC_OUT): $(BUILD_DIR)/laplace_%: laplace/%.upc laplace/settings.h
	@mkdir -p $(BUILD_DIR)
	$(UPCC) -T $(THREADS) $< -o $@

$(HEAT_UPC_OUT): $(BUILD_DIR)/%: 2d_heat/%.upc 2d_heat/settings.h
	@mkdir -p $(BUILD_DIR)
	$(UPCC) -T $(THREADS) $< -o $@

# $(BUILD_DIR)/laplace_ex3: laplace/ex3.upc settings.h
# 	@mkdir -p $(BUILD_DIR)
# 	$(UPCC) -T $(THREADS) laplace/ex3.upc -o $(BUILD_DIR)/laplace_ex3

# $(BUILD_DIR)/laplace_ex4: laplace/ex4.upc settings.h
# 	@mkdir -p $(BUILD_DIR)
# 	$(UPCC) -T $(THREADS) laplace/ex4.upc -o $(BUILD_DIR)/laplace_ex4

# $(BUILD_DIR)/laplace_ex5: laplace/ex5.upc settings.h
# 	@mkdir -p $(BUILD_DIR)
# 	$(UPCC) -T $(THREADS) laplace/ex5.upc -o $(BUILD_DIR)/laplace_ex5

# $(BUILD_DIR)/laplace_ex6: laplace/ex6.upc settings.h
# 	@mkdir -p $(BUILD_DIR)
# 	$(UPCC) -T $(THREADS) laplace/ex6.upc -o $(BUILD_DIR)/laplace_ex6

# $(BUILD_DIR)/laplace_optimized: laplace/optimized.upc settings.h
# 	@mkdir -p $(BUILD_DIR)
# 	$(UPCC) -T $(THREADS) laplace/optimized.upc -o $(BUILD_DIR)/laplace_optimized

PROJECT_NAME := ulp-i2c

# Get Path of ULP_Sensor
ULP_SENSOR_PATH := $(dir $(CURDIR))
ULP_SENSOR_PATH := $(dir $(ULP_SENSOR_PATH:%/=%))
ULP_SENSOR_PATH := $(realpath -s $(ULP_SENSOR_PATH))
$(info ULP_SENSOR_PATH is $(ULP_SENSOR_PATH))
export ULP_SENSOR_PATH

ifndef IDF_PATH
$(error IDF_PATH variable is not set to a valid directory.)
endif

include $(IDF_PATH)/make/project.mk
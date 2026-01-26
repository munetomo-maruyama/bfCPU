//===========================================================
// bfCPU Running Tool
//-----------------------------------------------------------
// File Name   : raspi.c
// Description : Raspberry Pi Control Routine
//-----------------------------------------------------------
// History :
// Rev.01 2025.11.03 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025-2026 M.Maruyama
//===========================================================

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <gpiod.h>
#include "raspi.h"

// CLK       : GPIO18
// RES_N     : GPIO23
// QSPI_CS_N : GPIO0
// QSPI_SCK  : GPIO5
// QSPI_SIO0 : GPIO6 (QSPI_SI)
// QSPI_SIO1 : GPIO13
// QSPI_SIO2 : GPIO19
// QSPI_SIO3 : GPIO26

//-------------------------
// GPIO Configurations
//-------------------------
#define GPIO_RESN_NUM_LINES 1
#define GPIO_CSN_NUM_LINES  1
#define GPIO_SCK_NUM_LINES  1
#define GPIO_SIO_NUM_LINES  4
#define GPIO_SI_NUM_LINES   1
//
static const unsigned int gpio_resn_offsets[] = {23};
static const unsigned int gpio_csn_offsets[]  = {0};
static const unsigned int gpio_sck_offsets[]  = {5};
static const unsigned int gpio_sio_offsets[]  = {6, 13, 19, 26};
static const unsigned int gpio_si_offsets[]   = {6};
//
struct gpiod_chip *chip;
//
struct gpiod_line_settings  *gpio_resn_settings;
struct gpiod_line_config    *gpio_resn_config;
struct gpiod_request_config *gpio_resn_req_cfg;
struct gpiod_line_request   *gpio_resn_request;
enum   gpiod_line_value      gpio_resn_values[GPIO_RESN_NUM_LINES];
//
struct gpiod_line_settings  *gpio_csn_settings;
struct gpiod_line_config    *gpio_csn_config;
struct gpiod_request_config *gpio_csn_req_cfg;
struct gpiod_line_request   *gpio_csn_request;
enum   gpiod_line_value      gpio_csn_values[GPIO_CSN_NUM_LINES];
//
struct gpiod_line_settings  *gpio_sck_settings;
struct gpiod_line_config    *gpio_sck_config;
struct gpiod_request_config *gpio_sck_req_cfg;
struct gpiod_line_request   *gpio_sck_request;
enum   gpiod_line_value      gpio_sck_values[GPIO_SCK_NUM_LINES];
//
struct gpiod_line_settings  *gpio_sio_settings;
struct gpiod_line_config    *gpio_sio_config;
struct gpiod_request_config *gpio_sio_req_cfg;
struct gpiod_line_request   *gpio_sio_request;
enum   gpiod_line_value      gpio_sio_values[GPIO_SIO_NUM_LINES];
//
struct gpiod_line_settings  *gpio_si_settings;
struct gpiod_line_config    *gpio_si_config;
struct gpiod_request_config *gpio_si_req_cfg;
struct gpiod_line_request   *gpio_si_request;
enum   gpiod_line_value      gpio_si_values[GPIO_SI_NUM_LINES];

//------------------------------
// System Clock Output (GPIO18)
//------------------------------
int SysClk_Output(int start)
{
    FILE *fp;
    char buffer[256];
    const char *cmd_check = "[ -d \"/sys/class/pwm/pwmchip0/pwm2\" ] && echo 1 || echo 0";
    int  exist;
    //
    // Check existence of the directory "/sys/class/pwm/pwmchip0/pwm2"
    fp = popen(cmd_check, "r");
    if (fp == NULL)
    {
        perror("popen failed");
        return EXIT_FAILURE;
    }
    //
    // Read 1st Line
    fgets(buffer, sizeof(buffer), fp);
    //
    // Close Pipe
    if (pclose(fp) == -1)
    {
        perror("pclose failed");
        return EXIT_FAILURE;
    }
    //
    // Exsistence
    exist = (buffer[0] == '1')? 1 : 0;
    //    
    // Create PWM Clock from GPIO18(PWM0-CHAN2)
    //     You need to add following line at bottom of /boot/firmware/config.txt
    //         dtoverlay=pwm-2chan
    if (exist == 0)
    {
	    system("echo   2 | sudo tee /sys/class/pwm/pwmchip0/export > /dev/null");
	    system("echo 100 | sudo tee /sys/class/pwm/pwmchip0/pwm2/period > /dev/null");
	    system("echo  50 | sudo tee /sys/class/pwm/pwmchip0/pwm2/duty_cycle > /dev/null");
    }
    // Start
    if (start)
    {
		system("echo   1 | sudo tee /sys/class/pwm/pwmchip0/pwm2/enable > /dev/null");
	}
	// Stop
	else
	{
		system("echo   0 | sudo tee /sys/class/pwm/pwmchip0/pwm2/enable > /dev/null");
	}
    //
    // Success
    return EXIT_SUCCESS;
}

//------------------------------
// CHIP Open
//------------------------------
void CHIP_Open(void)
{
    chip = gpiod_chip_open("/dev/gpiochip4");
}

//------------------------------
// CHIP Close
//------------------------------
void CHIP_Close(void)
{
    gpiod_chip_close(chip);
}

//------------------------------
// RES_N Initializaton
//------------------------------
void RESN_Init(void)
{
    gpio_resn_settings = gpiod_line_settings_new();
    gpio_resn_config   = gpiod_line_config_new();
    gpio_resn_req_cfg  = gpiod_request_config_new();
    //
    gpiod_line_settings_set_bias(gpio_resn_settings, GPIOD_LINE_BIAS_PULL_UP);
    gpiod_line_settings_set_drive(gpio_resn_settings, GPIOD_LINE_DRIVE_OPEN_DRAIN);    
    gpiod_line_settings_set_direction(gpio_resn_settings, GPIOD_LINE_DIRECTION_OUTPUT);
    gpiod_line_settings_set_output_value(gpio_resn_settings, 0); // default Low
    //
    gpiod_line_config_add_line_settings(
        gpio_resn_config, gpio_resn_offsets, GPIO_RESN_NUM_LINES, gpio_resn_settings);
    //
    gpio_resn_request = gpiod_chip_request_lines(chip, gpio_resn_req_cfg, gpio_resn_config);
}

//------------------------------
// RES_N Clean Up
//------------------------------
void RESN_CleanUp(void)
{
    gpiod_line_request_release(gpio_resn_request);
    gpiod_request_config_free(gpio_resn_req_cfg);
    gpiod_line_settings_free(gpio_resn_settings);
}

//-----------------------------
// GPIO_RES_N Set Value
//-----------------------------
void GPIO_RESN_Set_Value(int value)
{
	gpio_resn_values[0] = value & 0x01;
	gpiod_line_request_set_values(gpio_resn_request, gpio_resn_values);	
}

//------------------------------
// QSPI Initializaton
//------------------------------
void QSPI_Init(void)
{
    //---------------------------------------------
    // Initializaion of GPIO_CS_N (1bit)
    //---------------------------------------------
    gpio_csn_settings = gpiod_line_settings_new();
    gpio_csn_config   = gpiod_line_config_new();
    gpio_csn_req_cfg  = gpiod_request_config_new();
    //
    gpiod_line_settings_set_bias(gpio_csn_settings, GPIOD_LINE_BIAS_PULL_UP);
    gpiod_line_settings_set_drive(gpio_csn_settings, GPIOD_LINE_DRIVE_OPEN_DRAIN);    
    gpiod_line_settings_set_direction(gpio_csn_settings, GPIOD_LINE_DIRECTION_OUTPUT);
    gpiod_line_settings_set_output_value(gpio_csn_settings, 1); // default Hi-Z
    //
    gpiod_line_config_add_line_settings(
        gpio_csn_config, gpio_csn_offsets, GPIO_RESN_NUM_LINES, gpio_csn_settings);
    //
    gpio_csn_request = gpiod_chip_request_lines(chip, gpio_csn_req_cfg, gpio_csn_config);
    //
    //---------------------------------------------
    // Initializaion of GPIO_SCK (1bit)
    //---------------------------------------------
    gpio_sck_settings = gpiod_line_settings_new();
    gpio_sck_config   = gpiod_line_config_new();
    gpio_sck_req_cfg  = gpiod_request_config_new();
    //
    gpiod_line_settings_set_bias(gpio_sck_settings, GPIOD_LINE_BIAS_PULL_UP);
    gpiod_line_settings_set_drive(gpio_sck_settings, GPIOD_LINE_DRIVE_OPEN_DRAIN);    
    gpiod_line_settings_set_direction(gpio_sck_settings, GPIOD_LINE_DIRECTION_OUTPUT);
    gpiod_line_settings_set_output_value(gpio_sck_settings, 1); // default Hi-Z
    //
    gpiod_line_config_add_line_settings(
        gpio_sck_config, gpio_sck_offsets, GPIO_RESN_NUM_LINES, gpio_sck_settings);
    //
    gpio_sck_request = gpiod_chip_request_lines(chip, gpio_sck_req_cfg, gpio_sck_config);
    //    
    //---------------------------------------------
    // Initializaion of GPIO_SIO (4bit)
    //---------------------------------------------
    gpio_sio_settings = gpiod_line_settings_new();
    gpio_sio_config   = gpiod_line_config_new();
    gpio_sio_req_cfg  = gpiod_request_config_new();
    //
    gpiod_line_settings_set_bias(gpio_sio_settings, GPIOD_LINE_BIAS_PULL_UP);
    gpiod_line_settings_set_drive(gpio_sio_settings, GPIOD_LINE_DRIVE_OPEN_DRAIN);    
    gpiod_line_settings_set_direction(gpio_sio_settings, GPIOD_LINE_DIRECTION_OUTPUT);
    gpiod_line_settings_set_output_value(gpio_sio_settings, 1); // default Hi-Z
    //
    gpiod_line_config_add_line_settings(
        gpio_sio_config, gpio_sio_offsets, GPIO_SIO_NUM_LINES, gpio_sio_settings);
    //
    gpio_sio_request = gpiod_chip_request_lines(
        chip, gpio_sio_req_cfg, gpio_sio_config);
}

//------------------------------
// QSPI Cleanup
//------------------------------
void QSPI_CleanUp(void)
{
    gpiod_line_request_release(gpio_csn_request);
    gpiod_line_request_release(gpio_sck_request);
    gpiod_line_request_release(gpio_sio_request);
    gpiod_request_config_free(gpio_csn_req_cfg);
    gpiod_request_config_free(gpio_sck_req_cfg);
    gpiod_request_config_free(gpio_sio_req_cfg);
    gpiod_line_settings_free(gpio_csn_settings);
    gpiod_line_settings_free(gpio_sck_settings);
    gpiod_line_settings_free(gpio_sio_settings);
}

//------------------------------
// SPI Initializaton
//------------------------------
void SPI_Init(void)
{
    //---------------------------------------------
    // Initializaion of GPIO_CS_N (1bit)
    //---------------------------------------------
    gpio_csn_settings = gpiod_line_settings_new();
    gpio_csn_config   = gpiod_line_config_new();
    gpio_csn_req_cfg  = gpiod_request_config_new();
    //
    gpiod_line_settings_set_bias(gpio_csn_settings, GPIOD_LINE_BIAS_PULL_UP);
    gpiod_line_settings_set_drive(gpio_csn_settings, GPIOD_LINE_DRIVE_OPEN_DRAIN);    
    gpiod_line_settings_set_direction(gpio_csn_settings, GPIOD_LINE_DIRECTION_OUTPUT);
    gpiod_line_settings_set_output_value(gpio_csn_settings, 1); // default Hi-Z
    //
    gpiod_line_config_add_line_settings(
        gpio_csn_config, gpio_csn_offsets, GPIO_RESN_NUM_LINES, gpio_csn_settings);
    //
    gpio_csn_request = gpiod_chip_request_lines(chip, gpio_csn_req_cfg, gpio_csn_config);
    //
    //---------------------------------------------
    // Initializaion of GPIO_SCK (1bit)
    //---------------------------------------------
    gpio_sck_settings = gpiod_line_settings_new();
    gpio_sck_config   = gpiod_line_config_new();
    gpio_sck_req_cfg  = gpiod_request_config_new();
    //
    gpiod_line_settings_set_bias(gpio_sck_settings, GPIOD_LINE_BIAS_PULL_UP);
    gpiod_line_settings_set_drive(gpio_sck_settings, GPIOD_LINE_DRIVE_OPEN_DRAIN);    
    gpiod_line_settings_set_direction(gpio_sck_settings, GPIOD_LINE_DIRECTION_OUTPUT);
    gpiod_line_settings_set_output_value(gpio_sck_settings, 1); // default Hi-Z
    //
    gpiod_line_config_add_line_settings(
        gpio_sck_config, gpio_sck_offsets, GPIO_RESN_NUM_LINES, gpio_sck_settings);
    //
    gpio_sck_request = gpiod_chip_request_lines(chip, gpio_sck_req_cfg, gpio_sck_config);
    //---------------------------------------------
    // Initializaion of GPIO_SI (1bit)
    //---------------------------------------------
    gpio_si_settings = gpiod_line_settings_new();
    gpio_si_config   = gpiod_line_config_new();
    gpio_si_req_cfg  = gpiod_request_config_new();
    //
    gpiod_line_settings_set_bias(gpio_si_settings, GPIOD_LINE_BIAS_PULL_UP);
    gpiod_line_settings_set_drive(gpio_si_settings, GPIOD_LINE_DRIVE_OPEN_DRAIN);    
    gpiod_line_settings_set_direction(gpio_si_settings, GPIOD_LINE_DIRECTION_OUTPUT);
    gpiod_line_settings_set_output_value(gpio_si_settings, 1); // default Hi-Z
    //
    gpiod_line_config_add_line_settings(
        gpio_si_config, gpio_si_offsets, GPIO_SI_NUM_LINES, gpio_si_settings);
    //
    gpio_si_request = gpiod_chip_request_lines(chip, gpio_si_req_cfg, gpio_si_config);
}

//------------------------------
// SPI Cleanup
//------------------------------
void SPI_CleanUp(void)
{
    gpiod_line_request_release(gpio_csn_request);
    gpiod_line_request_release(gpio_sck_request);
    gpiod_line_request_release(gpio_si_request);
    gpiod_request_config_free(gpio_csn_req_cfg);
    gpiod_request_config_free(gpio_sck_req_cfg);
    gpiod_request_config_free(gpio_si_req_cfg);
    gpiod_line_settings_free(gpio_csn_settings);
    gpiod_line_settings_free(gpio_sck_settings);
    gpiod_line_settings_free(gpio_si_settings);
}

//----------------------------
// GPIO_CS_N Set Direction
//----------------------------
void GPIO_CS_N_Set_Direction(int direction)
{
	direction = (direction == 0)? GPIOD_LINE_DIRECTION_INPUT
	          : GPIOD_LINE_DIRECTION_OUTPUT;
    gpiod_line_settings_set_direction(gpio_csn_settings, direction);
    //
    gpiod_line_config_add_line_settings(
        gpio_csn_config, gpio_csn_offsets, GPIO_CSN_NUM_LINES, gpio_csn_settings);
    //
    gpio_csn_values[0] = 1;
    gpiod_line_request_set_values(gpio_csn_request, gpio_csn_values);
    //
    gpiod_line_request_reconfigure_lines(gpio_csn_request, gpio_csn_config);
}

//----------------------------
// GPIO_SCK Set Direction
//----------------------------
void GPIO_SCK_Set_Direction(int direction)
{
	direction = (direction == 0)? GPIOD_LINE_DIRECTION_INPUT
	          : GPIOD_LINE_DIRECTION_OUTPUT;
    gpiod_line_settings_set_direction(gpio_sck_settings, direction);
    //
    gpiod_line_config_add_line_settings(
        gpio_sck_config, gpio_sck_offsets, GPIO_SCK_NUM_LINES, gpio_sck_settings);
    //
    gpio_sck_values[0] = 0;
    gpiod_line_request_set_values(gpio_sck_request, gpio_sck_values);
    //
    gpiod_line_request_reconfigure_lines(gpio_sck_request, gpio_sck_config);
}

//----------------------------
// GPIO_SIO Set Direction
//----------------------------
void GPIO_SIO_Set_Direction(int direction)
{
	direction = (direction == 0)? GPIOD_LINE_DIRECTION_INPUT
	          : GPIOD_LINE_DIRECTION_OUTPUT;
    gpiod_line_settings_set_direction(gpio_sio_settings, direction);
    //
    gpiod_line_config_add_line_settings(
        gpio_sio_config, gpio_sio_offsets, GPIO_SIO_NUM_LINES, gpio_sio_settings);
    //
    gpio_sio_values[0] = 0;
    gpio_sio_values[1] = 0;
    gpio_sio_values[2] = 0;
    gpio_sio_values[3] = 0;
    gpiod_line_request_set_values(gpio_sio_request, gpio_sio_values);
    //
    gpiod_line_request_reconfigure_lines(gpio_sio_request, gpio_sio_config);
}

//----------------------------
// GPIO_SI Set Direction
//----------------------------
void GPIO_SI_Set_Direction(int direction)
{
	direction = (direction == 0)? GPIOD_LINE_DIRECTION_INPUT
	          : GPIOD_LINE_DIRECTION_OUTPUT;
    gpiod_line_settings_set_direction(gpio_si_settings, direction);
    //
    gpiod_line_config_add_line_settings(
        gpio_si_config, gpio_si_offsets, GPIO_SI_NUM_LINES, gpio_si_settings);
    //
    gpio_si_values[0] = 0;
    gpiod_line_request_set_values(gpio_si_request, gpio_si_values);
    //
    gpiod_line_request_reconfigure_lines(gpio_si_request, gpio_si_config);
}

//-----------------------------
// GPIO_CS_N Set Value
//-----------------------------
void GPIO_CSN_Set_Value(int value)
{
	gpio_csn_values[0] = value & 0x01;
	gpiod_line_request_set_values(gpio_csn_request, gpio_csn_values);	
}

//-----------------------------
// GPIO_SCK Set Value
//-----------------------------
void GPIO_SCK_Set_Value(int value)
{
	gpio_sck_values[0] = value & 0x01;
	gpiod_line_request_set_values(gpio_sck_request, gpio_sck_values);	
}

//-----------------------------
// GPIO_SIO Set Value
//-----------------------------
void GPIO_SIO_Set_Value(int value)
{
	gpio_sio_values[0] = (value >> 0) & 0x01;
	gpio_sio_values[1] = (value >> 1) & 0x01;
	gpio_sio_values[2] = (value >> 2) & 0x01;
	gpio_sio_values[3] = (value >> 3) & 0x01;
	gpiod_line_request_set_values(gpio_sio_request, gpio_sio_values);	
}

//-----------------------------
// GPIO_SIO Get Value
//-----------------------------
void GPIO_SIO_Get_Value(int *value)
{
	gpiod_line_request_get_values(gpio_sio_request, gpio_sio_values);
	*value = 0;
	*value = *value | (gpio_sio_values[0] << 0);
	*value = *value | (gpio_sio_values[1] << 1);
	*value = *value | (gpio_sio_values[2] << 2);
	*value = *value | (gpio_sio_values[3] << 3);
}

//-----------------------------
// GPIO_SI Set Value
//-----------------------------
void GPIO_SI_Set_Value(int value)
{
	gpio_si_values[0] = value & 0x01;
	gpiod_line_request_set_values(gpio_si_request, gpio_si_values);	
}

//-----------------------------
// GPIO_SI Get Value
//-----------------------------
void GPIO_SI_Get_Value(int *value)
{
	gpiod_line_request_get_values(gpio_si_request, gpio_si_values);
	*value = gpio_si_values[0];
}

//===========================================================
// End of File
//===========================================================

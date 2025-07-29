package config

import (
	"fmt"
	"os"

	"github.com/spf13/viper"
)

type Config struct {
	App        AppConfig        `mapstructure:"app"`
	Database   DatabaseConfig   `mapstructure:"database"`
	Redis      RedisConfig      `mapstructure:"redis"`
	Blockchain BlockchainConfig `mapstructure:"blockchain"`
	IPFS       IPFSConfig       `mapstructure:"ipfs"`
	JWT        JWTConfig        `mapstructure:"jwt"`
	Logging    LoggingConfig    `mapstructure:"logging"`
}

type AppConfig struct {
	Name    string `mapstructure:"name"`
	Version string `mapstructure:"version"`
	Env     string `mapstructure:"env"`
	Port    int    `mapstructure:"port"`
}

type DatabaseConfig struct {
	Host     string `mapstructure:"host"`
	Port     int    `mapstructure:"port"`
	User     string `mapstructure:"user"`
	Password string `mapstructure:"password"`
	Name     string `mapstructure:"name"`
	Charset  string `mapstructure:"charset"`
	MaxIdle  int    `mapstructure:"max_idle"`
	MaxOpen  int    `mapstructure:"max_open"`
}

type RedisConfig struct {
	Host     string `mapstructure:"host"`
	Port     int    `mapstructure:"port"`
	Password string `mapstructure:"password"`
	DB       int    `mapstructure:"db"`
	PoolSize int    `mapstructure:"pool_size"`
}

type BlockchainConfig struct {
	Network    string `mapstructure:"network"`
	RPCUrl     string `mapstructure:"rpc_url"`
	PrivateKey string `mapstructure:"private_key"`
	ChainID    int64  `mapstructure:"chain_id"`
}

type IPFSConfig struct {
	APIUrl     string `mapstructure:"api_url"`
	GatewayUrl string `mapstructure:"gateway_url"`
}

type JWTConfig struct {
	Secret    string `mapstructure:"secret"`
	ExpiresIn int    `mapstructure:"expires_in"`
}

type LoggingConfig struct {
	Level  string `mapstructure:"level"`
	Format string `mapstructure:"format"`
}

func Load() (*Config, error) {
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath("./configs")
	viper.AddConfigPath("../configs")
	viper.AddConfigPath("../../configs")

	// 支持环境变量覆盖
	viper.AutomaticEnv()
	viper.SetEnvPrefix("AI_PROVENANCE")

	if err := viper.ReadInConfig(); err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	var config Config
	if err := viper.Unmarshal(&config); err != nil {
		return nil, fmt.Errorf("failed to unmarshal config: %w", err)
	}

	// 从环境变量加载敏感信息
	if privateKey := os.Getenv("PRIVATE_KEY"); privateKey != "" {
		config.Blockchain.PrivateKey = privateKey
	}

	return &config, nil
}

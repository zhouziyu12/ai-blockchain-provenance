package main

import (
	"log"
	"ai-provenance-backend/internal/config"
	"fmt"
	"ai-provenance-backend/internal/api/routes"
	"github.com/gin-gonic/gin"
)

func main() {
	// 加载配置
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// 设置Gin模式
	if cfg.App.Env == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	// 创建路由
	router := routes.SetupRoutes(cfg)

	// 启动服务器
	log.Printf("Server starting on port %d", cfg.App.Port)
	if err := router.Run(fmt.Sprintf(":%d", cfg.App.Port)); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}

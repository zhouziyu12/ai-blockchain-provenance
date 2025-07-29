package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"ai-provenance-backend/internal/config"
	"ai-provenance-backend/internal/api/routes"
	"ai-provenance-backend/pkg/database"
	"ai-provenance-backend/pkg/logger"
	"ai-provenance-backend/pkg/redis"

	"github.com/gin-gonic/gin"
)

func main() {
	// 初始化日志
	logger.Init()
	logger.Info("🚀 启动AI模型溯源后端服务...")

	// 加载配置
	cfg, err := config.Load()
	if err != nil {
		logger.Fatal("Failed to load config", "error", err)
	}

	// 初始化数据库
	db, err := database.Init(cfg)
	if err != nil {
		logger.Fatal("Failed to initialize database", "error", err)
	}
	defer database.Close()

	// 初始化Redis
	redisClient, err := redis.Init(cfg)
	if err != nil {
		logger.Fatal("Failed to initialize redis", "error", err)
	}
	defer redis.Close()

	// 设置Gin模式
	if cfg.App.Env == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	// 创建路由
	router := routes.SetupRoutes(cfg, db, redisClient)

	// 创建HTTP服务器
	srv := &http.Server{
		Addr:         fmt.Sprintf(":%d", cfg.App.Port),
		Handler:      router,
		ReadTimeout:  time.Second * 15,
		WriteTimeout: time.Second * 15,
		IdleTimeout:  time.Second * 60,
	}

	// 启动服务器
	go func() {
		logger.Info("🌐 服务器启动", "port", cfg.App.Port, "env", cfg.App.Env)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("Failed to start server", "error", err)
		}
	}()

	// 优雅关闭
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info("🛑 正在关闭服务器...")

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		logger.Fatal("Server forced to shutdown", "error", err)
	}

	logger.Info("✅ 服务器已优雅关闭")
}

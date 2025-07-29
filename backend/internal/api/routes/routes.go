package routes

import (
	"ai-provenance-backend/internal/config"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

func SetupRoutes(cfg *config.Config) *gin.Engine {
	router := gin.Default()

	// CORS配置
	router.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"*"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
	}))

	// 健康检查
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":    "healthy",
			"service":   cfg.App.Name,
			"version":   cfg.App.Version,
			"timestamp": "2024-01-29T16:00:00Z",
		})
	})

	// API路由组
	v1 := router.Group("/api/v1")
	{
		v1.GET("/status", func(c *gin.Context) {
			c.JSON(200, gin.H{
				"message": "AI Provenance Backend API is running",
				"version": "1.0.0",
			})
		})
	}

	return router
}

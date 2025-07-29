package logger

import (
	"os"

	"github.com/sirupsen/logrus"
)

var log *logrus.Logger

// Init 初始化日志
func Init() {
	log = logrus.New()
	
	// 设置输出
	log.SetOutput(os.Stdout)
	
	// 设置日志格式
	log.SetFormatter(&logrus.JSONFormatter{
		TimestampFormat: "2006-01-02 15:04:05",
	})
	
	// 设置日志级别
	log.SetLevel(logrus.InfoLevel)
	
	// 开发环境使用文本格式
	if os.Getenv("GIN_MODE") != "release" {
		log.SetFormatter(&logrus.TextFormatter{
			FullTimestamp: true,
			ForceColors:   true,
		})
	}
}

// Info 记录信息日志
func Info(msg string, fields ...interface{}) {
	if len(fields)%2 != 0 {
		log.Info(msg)
		return
	}
	
	logFields := logrus.Fields{}
	for i := 0; i < len(fields); i += 2 {
		if key, ok := fields[i].(string); ok {
			logFields[key] = fields[i+1]
		}
	}
	
	log.WithFields(logFields).Info(msg)
}

// Error 记录错误日志
func Error(msg string, fields ...interface{}) {
	if len(fields)%2 != 0 {
		log.Error(msg)
		return
	}
	
	logFields := logrus.Fields{}
	for i := 0; i < len(fields); i += 2 {
		if key, ok := fields[i].(string); ok {
			logFields[key] = fields[i+1]
		}
	}
	
	log.WithFields(logFields).Error(msg)
}

// Fatal 记录致命错误日志
func Fatal(msg string, fields ...interface{}) {
	if len(fields)%2 != 0 {
		log.Fatal(msg)
		return
	}
	
	logFields := logrus.Fields{}
	for i := 0; i < len(fields); i += 2 {
		if key, ok := fields[i].(string); ok {
			logFields[key] = fields[i+1]
		}
	}
	
	log.WithFields(logFields).Fatal(msg)
}

// Debug 记录调试日志
func Debug(msg string, fields ...interface{}) {
	if len(fields)%2 != 0 {
		log.Debug(msg)
		return
	}
	
	logFields := logrus.Fields{}
	for i := 0; i < len(fields); i += 2 {
		if key, ok := fields[i].(string); ok {
			logFields[key] = fields[i+1]
		}
	}
	
	log.WithFields(logFields).Debug(msg)
}

// Warn 记录警告日志
func Warn(msg string, fields ...interface{}) {
	if len(fields)%2 != 0 {
		log.Warn(msg)
		return
	}
	
	logFields := logrus.Fields{}
	for i := 0; i < len(fields); i += 2 {
		if key, ok := fields[i].(string); ok {
			logFields[key] = fields[i+1]
		}
	}
	
	log.WithFields(logFields).Warn(msg)
}

// GetLogger 获取日志实例
func GetLogger() *logrus.Logger {
	return log
}

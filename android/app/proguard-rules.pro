# 💡 Workmanagerの内部データベースや重要なクラスを製品版でも絶対に削らせない設定
-keep class androidx.work.impl.** { *; }
-keep class dev.fluttercommunity.workmanager.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Roomデータベース（Workmanagerの裏方）のクラッシュ防止お守り
-keep class * extends androidx.room.RoomDatabase { *; }
-dontwarn androidx.work.impl.**
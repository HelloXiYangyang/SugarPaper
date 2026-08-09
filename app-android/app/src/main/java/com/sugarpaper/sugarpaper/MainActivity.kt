package com.sugarpaper.sugarpaper

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sugarpaper.sugarpaper.ui.theme.SugarColors

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { AppShell() }
    }
}

private val tabs = listOf("首页", "日历", "专注", "统计", "我的")

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppShell() {
    var tab by remember { mutableStateOf("首页") }
    var dark by remember { mutableStateOf(false) }
    val bg = if (dark) SugarColors.DarkBackground else SugarColors.Background
    val surface = if (dark) SugarColors.DarkSurface else SugarColors.Surface
    val text = if (dark) SugarColors.DarkText else SugarColors.Text

    MaterialTheme(
        colorScheme = if (dark) darkColorScheme() else lightColorScheme(
            primary = SugarColors.Brand,
            background = bg,
            surface = surface
        )
    ) {
        Scaffold(
            containerColor = bg,
            bottomBar = {
                NavigationBar(containerColor = surface) {
                    tabs.forEach { t ->
                        NavigationBarItem(
                            selected = tab == t,
                            onClick = { tab = t },
                            icon = { Text(t, fontSize = 12.sp, color = if (tab == t) SugarColors.Brand else Color(0xFFA0A0A0)) },
                            label = {},
                            colors = NavigationBarItemDefaults.colors(
                                indicatorColor = SugarColors.BrandSoft
                            )
                        )
                    }
                }
            }
        ) { padding ->
            if (tab == "首页") HomeView(padding, dark, { dark = !dark }, text, surface) else {
                Text("${tab} 视图（重写中）", Modifier.padding(padding), color = text)
            }
        }
    }
}

@Composable
private fun HomeView(
    padding: PaddingValues,
    dark: Boolean,
    toggleDark: () -> Unit,
    text: Color,
    surface: Color
) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(padding)
            .padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        item {
            Row(
                Modifier
                    .fillMaxWidth()
                    .padding(top = 14.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("今天", fontSize = 22.sp, fontWeight = FontWeight.Bold, color = text, modifier = Modifier.weight(1f))
                TextButton(onClick = toggleDark) { Text(if (dark) "浅" else "深", color = SugarColors.Brand) }
            }
        }
        item {
            OverviewCard(surface, text)
        }
        item {
            OutlinedTextField(
                value = "",
                onValueChange = {},
                placeholder = { Text("添加作业…", color = Color(0xFFA0A0A0)) },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(50),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = SugarColors.Brand,
                    unfocusedBorderColor = Color(0xFFEBEBEB),
                    focusedContainerColor = Color(0xFFF7F7F7),
                    unfocusedContainerColor = Color(0xFFF7F7F7)
                )
            )
        }
        item { GroupHeader("今天（4）", surface, text) }
        items(4) { i -> TaskRow("示例作业 ${i + 1}", surface, text) }
        item { GroupHeader("已逾期（1）", surface, text) }
        item { TaskRow("实验报告", surface, text, danger = true) }
    }
}

@Composable
private fun OverviewCard(surface: Color, text: Color) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Row(
            Modifier.padding(18.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                Modifier
                    .size(72.dp)
                    .background(SugarColors.BrandSoft, CircleShape),
                contentAlignment = Alignment.Center
            ) { Text("68%", fontWeight = FontWeight.Bold, color = SugarColors.Brand) }
            Column(Modifier.padding(start = 18.dp)) {
                Metric("今日进度", "68%", text)
                Metric("连续完成", "3 天", text)
                Metric("今日 XP", "45", text)
            }
        }
    }
}

@Composable
private fun Metric(key: String, value: String, text: Color) {
    Row(Modifier.fillMaxWidth().padding(vertical = 2.dp)) {
        Text(key, fontSize = 13.sp, color = Color(0xFF6E6E6E), modifier = Modifier.weight(1f))
        Text(value, fontSize = 13.sp, fontWeight = FontWeight.SemiBold, color = text)
    }
}

@Composable
private fun GroupHeader(title: String, surface: Color, text: Color) {
    Row(
        Modifier
            .fillMaxWidth()
            .background(surface, RoundedCornerShape(14.dp))
            .padding(horizontal = 16.dp, vertical = 12.dp)
    ) {
        Text(title, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = text)
    }
}

@Composable
private fun TaskRow(title: String, surface: Color, text: Color, danger: Boolean = false) {
    Row(
        Modifier
            .fillMaxWidth()
            .background(surface, RoundedCornerShape(14.dp))
            .padding(horizontal = 14.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(Modifier.size(22.dp).background(Color.Transparent, CircleShape))
        Column(Modifier.padding(start = 12.dp)) {
            Text(title, fontSize = 15.sp, fontWeight = FontWeight.Medium, color = text)
            Text(if (danger) "逾期 2 天" else "今天", fontSize = 12.sp, color = if (danger) Color(0xFFE5484D) else Color(0xFFA0A0A0))
        }
    }
}

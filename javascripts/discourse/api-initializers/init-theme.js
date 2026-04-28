import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.34", (api) => {
  const user = api.getCurrentUser();
  if (!user) return;

  // DEBUG: ver estrutura do user
  console.log("[v0] User object:", user);
  console.log("[v0] ignored_usernames:", user.ignored_usernames);
  console.log("[v0] ignored_users:", user.ignored_users);
  
  // Tenta encontrar a lista de ignorados
  const ignoredUsers = user.ignored_usernames || user.ignored_users || [];
  console.log("[v0] Final ignoredUsers:", ignoredUsers);

  if (ignoredUsers.length === 0) {
    console.log("[v0] Nenhum usuário ignorado encontrado!");
    return;
  }

  function hideIgnoredTopicsInLatestList() {
    const latestItems = document.querySelectorAll(".latest-topic-list-item:not([data-v0-checked])");
    console.log("[v0] Itens encontrados:", latestItems.length);
    
    latestItems.forEach((item) => {
      item.setAttribute("data-v0-checked", "true");
      
      const userCard = item.querySelector(".topic-poster a[data-user-card]");
      const username = userCard?.getAttribute("data-user-card");
      
      console.log("[v0] Tópico:", item.querySelector(".title")?.textContent?.substring(0, 30));
      console.log("[v0] Username do autor:", username);
      
      if (username) {
        const isIgnored = ignoredUsers.some(
          u => u.toLowerCase() === username.toLowerCase()
        );
        console.log("[v0] Está ignorado?", isIgnored);
        
        if (isIgnored) {
          item.style.display = "none";
          console.log("[v0] ESCONDENDO tópico!");
        }
      }
    });
  }

  api.onPageChange(() => {
    setTimeout(hideIgnoredTopicsInLatestList, 500);
  });
});

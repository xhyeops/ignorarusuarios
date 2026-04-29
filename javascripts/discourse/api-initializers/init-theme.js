import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.34", (api) => {
  const user = api.getCurrentUser();
  if (!user) return;

  const ignoredUsers = user.ignored_users || [];
  if (ignoredUsers.length === 0) return;

  const ignoredUsersLower = ignoredUsers.map(u => u.toLowerCase());
  const checkedTopics = new Set();

  // Para tabela de tópicos tradicional
  api.registerValueTransformer(
    "topic-list-item-class",
    ({ value, context: { topic } }) => {
      if (
        topic?.creator &&
        ignoredUsersLower.includes(topic.creator.username.toLowerCase())
      ) {
        value.push("hidden-topic");
      }
      return value;
    }
  );

  // Para lista de tópicos recentes - busca via API
  async function hideIgnoredTopicsInLatestList() {
    const latestItems = document.querySelectorAll(".latest-topic-list-item:not([data-v0-processed])");

    for (const item of latestItems) {
      item.setAttribute("data-v0-processed", "true");

      const topicId = item.getAttribute("data-topic-id");
      if (!topicId || checkedTopics.has(topicId)) continue;

      checkedTopics.add(topicId);

      try {
        const response = await fetch(`/t/${topicId}.json`);
        const data = await response.json();
        
        const creatorUsername = data.details?.created_by?.username;

        if (creatorUsername && ignoredUsersLower.includes(creatorUsername.toLowerCase())) {
          item.style.display = "none";
        }
      } catch (e) {
        // Silenciosamente ignora erros
      }
    }
  }

  api.onPageChange(() => {
    setTimeout(hideIgnoredTopicsInLatestList, 300);
  });
});

import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.34", (api) => {
  const hideAvatar = settings.hide_ignored_users_avatar;
  const hideTopics = settings.hide_ignored_user_topics;

  if (!hideAvatar && !hideTopics) return;

  const user = api.getCurrentUser();
  if (!user) return;

  const ignoredUsers = user.ignored_users || [];
  if (!ignoredUsers.length) return;

  function isIgnoredUser(username) {
    return ignoredUsers.includes(username);
  }

  function getUsername(poster) {
    return poster?.user?.username || poster?.username;
  }

  function isIgnoredTopicCreator(topic) {
    const posters = topic.posters || [];

    if (posters.length > 0) {
      const username = getUsername(posters[0]);
      if (username) return isIgnoredUser(username);
    }

    const creatorUsername = topic.creator?.username || topic.user?.username;
    if (creatorUsername) return isIgnoredUser(creatorUsername);

    return false;
  }

  function isLatestPosterIgnored(topic) {
    const posters = topic.posters || [];

    return posters.some((poster) => {
      const username = getUsername(poster);
      const description = poster?.description?.toLowerCase?.() || "";

      const isLatest =
        poster?.extras === "latest" ||
        description.includes("most recent") ||
        description.includes("último") ||
        description.includes("mais recente");

      return username && isLatest && isIgnoredUser(username);
    });
  }

  // Adiciona classes na lista de tópicos
  api.registerValueTransformer("topic-list-item-class", ({ value, context }) => {
    const topic = context?.topic;
    if (!topic) return value;

    if (hideTopics && isIgnoredTopicCreator(topic)) {
      value.push("ignored-op-topic");
    }

    if (hideAvatar && isLatestPosterIgnored(topic)) {
      value.push("ignored-latest-poster");
    }

    return value;
  });

  api.registerValueTransformer("topic-list-class", ({ value }) => {
    value.push("ignore-plus-enabled");
    return value;
  });

  // 🔥 FUNÇÃO QUE TROCA O ÚLTIMO PELO PENÚLTIMO
  function promotePreviousPoster() {
    document.querySelectorAll("tr.ignored-latest-poster td.posters").forEach((postersCell) => {
      const latestPoster = postersCell.querySelector("a.latest");

      if (!latestPoster) return;

      // remove o último ignorado
      latestPoster.remove();

      const posters = postersCell.querySelectorAll("a");

      if (!posters.length) return;

      // pega o novo último (penúltimo original)
      const previousPoster = posters[posters.length - 1];

      previousPoster.classList.add("latest");

      const avatar = previousPoster.querySelector("img.avatar");

      if (avatar) {
        avatar.classList.add("latest");

        if (avatar.title) {
          avatar.title = avatar.title.replace(
            /Autor\(a\).*$/,
            "Autor(a) mais recente"
          );
        }
      }
    });
  }

  // Executa ao trocar de página
  api.onPageChange(() => {
    setTimeout(promotePreviousPoster, 300);
    setTimeout(promotePreviousPoster, 1000);
  });
});

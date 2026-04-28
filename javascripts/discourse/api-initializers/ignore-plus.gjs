import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.34", (api) => {
  const hideAvatar = settings.hide_ignored_users_avatar;
  const hideTopics = settings.hide_ignored_user_topics;

  if (!hideAvatar && !hideTopics) return;

  const user = api.getCurrentUser();
  if (!user) return;

  const ignoredUsers = user.ignored_users || [];
  if (!ignoredUsers.length) return;

  function normalize(value) {
    return value?.toString?.().toLowerCase().trim();
  }

  function isIgnoredUser(username) {
    const normalized = normalize(username);
    return ignoredUsers.some((ignored) => normalize(ignored) === normalized);
  }

  function getUsernameFromPosterLink(link) {
    const dataUserCard = link.getAttribute("data-user-card");
    if (dataUserCard) return dataUserCard;

    const href = link.getAttribute("href");
    if (href?.startsWith("/u/")) {
      return href.replace("/u/", "").split("/")[0];
    }

    return null;
  }

  function getUsernameFromPosterObject(poster) {
    return poster?.user?.username || poster?.username;
  }

  function isIgnoredTopicCreator(topic) {
    const posters = topic.posters || [];

    if (posters.length > 0) {
      const username = getUsernameFromPosterObject(posters[0]);
      if (username) return isIgnoredUser(username);
    }

    const creatorUsername = topic.creator?.username || topic.user?.username;
    if (creatorUsername) return isIgnoredUser(creatorUsername);

    return false;
  }

  api.registerValueTransformer("topic-list-item-class", ({ value, context }) => {
    const topic = context?.topic;
    if (!topic) return value;

    if (hideTopics && isIgnoredTopicCreator(topic)) {
      value.push("ignored-op-topic");
    }

    return value;
  });

  api.registerValueTransformer("topic-list-class", ({ value }) => {
    value.push("ignore-plus-enabled");
    return value;
  });

  function fixPosterList() {
    if (!hideAvatar) return;

    document.querySelectorAll("td.posters").forEach((postersCell) => {
      const posterLinks = Array.from(postersCell.querySelectorAll("a"));

      if (!posterLinks.length) return;

      posterLinks.forEach((link) => {
        const username = getUsernameFromPosterLink(link);

        if (username && isIgnoredUser(username)) {
          link.remove();
        }
      });

      const remainingPosters = Array.from(postersCell.querySelectorAll("a"));

      remainingPosters.forEach((link) => {
        link.classList.remove("latest");

        const avatar = link.querySelector("img.avatar");
        if (avatar) {
          avatar.classList.remove("latest");
        }
      });

      const newLatest = remainingPosters[remainingPosters.length - 1];

      if (newLatest) {
        newLatest.classList.add("latest");

        const avatar = newLatest.querySelector("img.avatar");

        if (avatar) {
          avatar.classList.add("latest");

          if (avatar.title) {
            avatar.title = avatar.title.replace(
              /Autor\(a\).*$/,
              "Autor(a) mais recente"
            );
          }
        }
      }
    });
  }

  function hideIgnoredQuotes() {
    document.querySelectorAll(".quote").forEach((quote) => {
      const username =
        quote.querySelector("[data-user-card]")?.getAttribute("data-user-card") ||
        quote.querySelector("a[href^='/u/']")?.getAttribute("href")?.replace("/u/", "").split("/")[0];

      if (username && isIgnoredUser(username)) {
        quote.classList.add("ignored-user-quote");
      }
    });
  }

  function runIgnorePlusFixes() {
    fixPosterList();
    hideIgnoredQuotes();
  }

  api.onPageChange(() => {
    setTimeout(runIgnorePlusFixes, 300);
    setTimeout(runIgnorePlusFixes, 1000);
    setTimeout(runIgnorePlusFixes, 2000);
  });

  const observer = new MutationObserver(() => {
    runIgnorePlusFixes();
  });

  observer.observe(document.body, {
    childList: true,
    subtree: true,
  });
});

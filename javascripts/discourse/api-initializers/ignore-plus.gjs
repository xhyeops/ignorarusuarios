import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.34", (api) => {
  const hideAvatar = settings.hide_ignored_users_avatar;
  const hideTopics = settings.hide_ignored_user_topics;

  if (!hideAvatar && !hideTopics) return;

  const user = api.getCurrentUser();
  if (!user) return;

  const ignoredUsers = user.ignored_users || [];
  if (!ignoredUsers.length) return;

  function normalizeUsername(username) {
    return username?.toLowerCase?.().trim();
  }

  function isIgnoredUser(username) {
    const normalized = normalizeUsername(username);

    return ignoredUsers.some(
      (ignored) => normalizeUsername(ignored) === normalized
    );
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

  function getUsernameFromPosterLink(link) {
    const dataUserCard = link.getAttribute("data-user-card");
    if (dataUserCard) return dataUserCard;

    const href = link.getAttribute("href");
    if (href?.startsWith("/u/")) {
      return href.replace("/u/", "").split("/")[0];
    }

    return null;
  }

  function promotePreviousPoster() {
    if (!hideAvatar) return;

    document.querySelectorAll("td.posters").forEach((postersCell) => {
      const latestPoster = postersCell.querySelector("a.latest");

      if (!latestPoster) return;

      const latestUsername = getUsernameFromPosterLink(latestPoster);

      if (!latestUsername || !isIgnoredUser(latestUsername)) return;

      latestPoster.remove();

      const remainingPosters = postersCell.querySelectorAll("a");

      if (!remainingPosters.length) return;

      const previousPoster = remainingPosters[remainingPosters.length - 1];

      previousPoster.classList.add("latest");

      const previousAvatar = previousPoster.querySelector("img.avatar");

      if (previousAvatar) {
        previousAvatar.classList.add("latest");

        if (previousAvatar.title) {
          previousAvatar.title = previousAvatar.title.replace(
            /Autor\(a\).*$/,
            "Autor(a) mais recente"
          );
        }
      }
    });
  }

  api.onPageChange(() => {
    setTimeout(promotePreviousPoster, 300);
    setTimeout(promotePreviousPoster, 1000);
    setTimeout(promotePreviousPoster, 2000);
  });
});

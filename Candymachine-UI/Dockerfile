#creating and using the direcotry as the work directory
ARG IMG
FROM node:${IMG}
ARG LOCATION
RUN mkdir -p /usr/src/${LOCATION}
WORKDIR /usr/src/${LOCATION}

#copy all the source to docker
COPY . /usr/src/${LOCATION}
ARG NODE_ENV
CMD export NODE_ENV=${NODE_ENV}

# check node and npm version
RUN node -v
RUN npm -v

RUN npm install --legacy-peer-deps
RUN npm run build

#start the server
CMD ["npm", "start"]
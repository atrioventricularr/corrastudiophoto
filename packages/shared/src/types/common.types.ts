export type CorraId = string;

export type ISODateTimeString = string;

export type UrlString = string;

export type Nullable<T> = T | null;

export type Maybe<T> = T | undefined;

export type ResultSuccess<T> = {
  ok: true;
  data: T;
};

export type ResultFailure = {
  ok: false;
  error: {
    code: string;
    message: string;
    details?: unknown;
  };
};

export type AppResult<T> = ResultSuccess<T> | ResultFailure;
